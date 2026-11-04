#import <UIKit/UIKit.h>

#pragma mark - CẤU HÌNH (điền link + tên file ở đây)

// title : tên nút trong menu
// url   : direct link (nên dùng https)
// subdir: thư mục con trong Library/Application Support/No_Backup ("" = ngay trong No_Backup)
// file  : TÊN FILE sẽ bị thay thế (xem bằng Filza)
static NSArray<NSDictionary *> *Items(void) {
    return @[
        @{ @"title": @"Mở cây",
           @"url":   @"https://archive.org/download/pp_20261103/pp.dat",
           @"subdir": @"",
           @"file":  @"pp.dat" },
        @{ @"title": @"0 Sun 0 Cooldown",
           @"url":   @"https://archive.org/download/plant-levels/PlantLevels.rton",
           @"subdir": @"CDN.13.5",
           @"file":  @"PlantLevels.rton" },
        @{ @"title": @"Freeshop",
           @"url":   @"https://archive.org/download/products_202611/products.rton",
           @"subdir": @"CDN.13.5",
           @"file":  @"products.rton" },
    ];
}

// Danh sách cuộn: hiện tối đa kVisibleRows nút cùng lúc, nhiều hơn thì vuốt lên xuống
#define kRowH        40
#define kRowGap      8
#define kVisibleRows 3

#pragma mark - CREDIT (điền link Facebook)

static NSString *const kLinkBach = @"https://www.facebook.com/share/19r75Kb5d4/?mibextid=wwXIfr";
static NSString *const kLinkDuc  = @"https://www.facebook.com/share/1FQfuugTjG/?mibextid=wwXIfr";
static NSString *const kLinkHuy  = @"https://www.facebook.com/share/1CXT3fSzWe/?mibextid=wwXIfr";

static NSAttributedString *CreditText(void) {
    NSMutableAttributedString *a = [NSMutableAttributedString new];
    NSDictionary *base = @{ NSFontAttributeName: [UIFont systemFontOfSize:12],
                            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.75 alpha:1] };
    void (^plain)(NSString *) = ^(NSString *t) {
        [a appendAttributedString:[[NSAttributedString alloc] initWithString:t attributes:base]];
    };
    void (^link)(NSString *, NSString *) = ^(NSString *name, NSString *url) {
        NSMutableDictionary *d = [base mutableCopy];
        d[NSFontAttributeName] = [UIFont boldSystemFontOfSize:12];
        NSURL *u = [NSURL URLWithString:url];
        if (u) d[NSLinkAttributeName] = u;
        [a appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:d]];
    };
    plain(@"Develop by ");       link(@"Bach", kLinkBach);
    plain(@"\nSpecial thanks: "); link(@"Duc Nguyen", kLinkDuc);
    plain(@" and ");             link(@"Nguyễn Huy", kLinkHuy);

    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.alignment = NSTextAlignmentCenter;
    [a addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, a.length)];
    return a;
}

#pragma mark - Tải & thay file

static void DownloadAndReplace(NSDictionary *item, void (^done)(BOOL ok, NSString *msg)) {
    NSString *urlStr = item[@"url"];
    NSString *name = item[@"file"];
    if ([urlStr containsString:@"example.com"] || [name hasPrefix:@"TEN_FILE"]) {
        done(NO, @"Chưa điền link / tên file trong Tweak.m");
        return;
    }
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url || name.length == 0 || [name containsString:@"/"] || [name containsString:@".."]) {
        done(NO, @"Link hoặc tên file không hợp lệ");
        return;
    }

    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/No_Backup"];
    NSString *sub = item[@"subdir"];
    if (sub.length) dir = [dir stringByAppendingPathComponent:sub];
    NSString *dest = [dir stringByAppendingPathComponent:name];

    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    cfg.timeoutIntervalForRequest = 30;
    cfg.timeoutIntervalForResource = 300;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg];

    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url
        completionHandler:^(NSURL *tmp, NSURLResponse *resp, NSError *err) {
        BOOL ok = NO;
        NSString *msg = nil;
        NSInteger code = [resp isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)resp).statusCode : 0;

        if (err) {
            msg = err.localizedDescription;
        } else if (code != 200) {
            msg = [NSString stringWithFormat:@"Server trả về lỗi HTTP %ld", (long)code];
        } else {
            NSFileManager *fm = NSFileManager.defaultManager;
            NSError *e = nil;
            unsigned long long size = [[fm attributesOfItemAtPath:tmp.path error:nil] fileSize];
            if (size == 0) {
                msg = @"File tải về bị rỗng";
            } else if (![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&e]) {
                msg = e.localizedDescription;
            } else {
                // Sao lưu file gốc 1 lần duy nhất (.bak)
                NSString *bak = [dest stringByAppendingString:@".bak"];
                if ([fm fileExistsAtPath:dest] && ![fm fileExistsAtPath:bak]) {
                    [fm copyItemAtPath:dest toPath:bak error:nil];
                }
                NSURL *destURL = [NSURL fileURLWithPath:dest];
                if ([fm fileExistsAtPath:dest]) {
                    ok = [fm replaceItemAtURL:destURL withItemAtURL:tmp backupItemName:nil
                                      options:0 resultingItemURL:nil error:&e];
                } else {
                    ok = [fm moveItemAtURL:tmp toURL:destURL error:&e];
                }
                msg = ok ? @"Xong! Thoát hẳn game rồi mở lại để áp dụng." : e.localizedDescription;
            }
        }
        [session finishTasksAndInvalidate];
        dispatch_async(dispatch_get_main_queue(), ^{ done(ok, msg); });
    }];
    [task resume];
}

#pragma mark - Window cho phép chạm xuyên qua vào game

@interface PassthroughWindow : UIWindow
@end
@implementation PassthroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    return (v == self || v == self.rootViewController.view) ? nil : v;
}
@end

#pragma mark - Icon nổi + menu

@interface MenuVC : UIViewController <UITextViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIButton *floatBtn;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIPanGestureRecognizer *panelPan;
@property (nonatomic, strong) NSLayoutConstraint *panelCX;
@property (nonatomic, strong) NSLayoutConstraint *panelCY;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) NSMutableArray<UIButton *> *itemBtns;
@end

@implementation MenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.itemBtns = [NSMutableArray array];
    [self buildPanel];
    [self buildFloatButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.floatBtn.center = [self clamped:self.floatBtn.center];
    [self clampPanel];
}

- (CGPoint)clamped:(CGPoint)c {
    CGRect r = CGRectInset(self.view.bounds, 26, 26);
    c.x = MIN(MAX(c.x, CGRectGetMinX(r)), CGRectGetMaxX(r));
    c.y = MIN(MAX(c.y, CGRectGetMinY(r)), CGRectGetMaxY(r));
    return c;
}

- (UIButton *)actionButton:(NSString *)title color:(UIColor *)color {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [b setTitleColor:[UIColor colorWithWhite:1 alpha:0.4] forState:UIControlStateDisabled];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    b.backgroundColor = color;
    b.layer.cornerRadius = 10;
    [b.heightAnchor constraintEqualToConstant:kRowH].active = YES;
    return b;
}

- (void)buildFloatButton {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = CGRectMake(20, 120, 52, 52);
    b.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
    b.layer.cornerRadius = 26;
    b.layer.borderWidth = 1.5;
    b.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;

    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(13, 13, 26, 26)];
    dot.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
    dot.layer.cornerRadius = 13;
    dot.userInteractionEnabled = NO;
    [b addSubview:dot];

    [b addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [b addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)]];
    [self.view addSubview:b];
    self.floatBtn = b;
}

- (void)buildPanel {
    UIView *p = [UIView new];
    p.translatesAutoresizingMaskIntoConstraints = NO;
    p.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.96];
    p.layer.cornerRadius = 16;
    p.hidden = YES;

    UILabel *title = [UILabel new];
    title.text = @"Menu";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:15];
    title.textAlignment = NSTextAlignmentCenter;

    UIStackView *st = [[UIStackView alloc] initWithArrangedSubviews:@[title]];
    st.axis = UILayoutConstraintAxisVertical;
    st.spacing = 8;
    st.translatesAutoresizingMaskIntoConstraints = NO;

    // Danh sách chức năng (cuộn lên xuống nếu nhiều hơn kVisibleRows)
    NSArray *items = Items();
    UIStackView *list = [[UIStackView alloc] init];
    list.axis = UILayoutConstraintAxisVertical;
    list.spacing = kRowGap;
    list.translatesAutoresizingMaskIntoConstraints = NO;

    for (NSUInteger i = 0; i < items.count; i++) {
        UIButton *b = [self actionButton:items[i][@"title"]
                                   color:[UIColor colorWithRed:0.18 green:0.62 blue:0.35 alpha:1]];
        b.tag = i;
        [b addTarget:self action:@selector(onItem:) forControlEvents:UIControlEventTouchUpInside];
        [list addArrangedSubview:b];
        [self.itemBtns addObject:b];
    }

    UIScrollView *sv = [UIScrollView new];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    sv.showsVerticalScrollIndicator = YES;
    sv.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    sv.alwaysBounceVertical = NO;
    [sv addSubview:list];

    CGFloat fullH = items.count ? items.count * kRowH + (items.count - 1) * kRowGap : 0;
    CGFloat maxH  = kVisibleRows * kRowH + (kVisibleRows - 1) * kRowGap;
    [NSLayoutConstraint activateConstraints:@[
        [list.topAnchor constraintEqualToAnchor:sv.topAnchor],
        [list.bottomAnchor constraintEqualToAnchor:sv.bottomAnchor],
        [list.leadingAnchor constraintEqualToAnchor:sv.leadingAnchor],
        [list.trailingAnchor constraintEqualToAnchor:sv.trailingAnchor],
        [list.widthAnchor constraintEqualToAnchor:sv.widthAnchor],
        [sv.heightAnchor constraintEqualToConstant:MIN(fullH, maxH)],
    ]];
    [st addArrangedSubview:sv];
    self.scroll = sv;

    UILabel *s = [UILabel new];
    s.text = @"Sẵn sàng";
    s.textColor = [UIColor colorWithWhite:0.85 alpha:1];
    s.font = [UIFont systemFontOfSize:13];
    s.numberOfLines = 0;
    s.textAlignment = NSTextAlignmentCenter;
    [st addArrangedSubview:s];
    self.status = s;

    UITextView *tv = [UITextView new];
    tv.editable = NO;
    tv.selectable = YES;
    tv.scrollEnabled = NO;
    tv.backgroundColor = UIColor.clearColor;
    tv.textContainerInset = UIEdgeInsetsZero;
    tv.attributedText = CreditText();
    tv.linkTextAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:0.4 green:0.7 blue:1 alpha:1],
                               NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) };
    tv.delegate = self;
    [st addArrangedSubview:tv];

    UIButton *close = [self actionButton:@"Đóng" color:[UIColor colorWithWhite:0.3 alpha:1]];
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [st addArrangedSubview:close];

    [p addSubview:st];
    [self.view addSubview:p];
    self.panel = p;

    self.panelCX = [p.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    self.panelCY = [p.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
    UIPanGestureRecognizer *pp = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanelPan:)];
    pp.delegate = self;
    [p addGestureRecognizer:pp];
    self.panelPan = pp;

    [NSLayoutConstraint activateConstraints:@[
        self.panelCX,
        self.panelCY,
        [p.widthAnchor constraintEqualToConstant:260],
        [st.topAnchor constraintEqualToAnchor:p.topAnchor constant:16],
        [st.bottomAnchor constraintEqualToAnchor:p.bottomAnchor constant:-16],
        [st.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:16],
        [st.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-16],
    ]];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)range
    interaction:(UITextItemInteraction)interaction {
    if (interaction == UITextItemInteractionInvokeDefaultAction) {
        [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
    }
    return NO;
}

// Kéo panel chỉ hoạt động ngoài vùng danh sách (trong danh sách thì để cuộn)
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)touch {
    if (g == self.panelPan && self.scroll && [touch.view isDescendantOfView:self.scroll]) return NO;
    return YES;
}

- (void)onPanelPan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.view];
    [g setTranslation:CGPointZero inView:self.view];
    self.panelCX.constant += t.x;
    self.panelCY.constant += t.y;
    [self clampPanel];
    [self.view layoutIfNeeded];
}

// Không cho kéo panel ra khỏi màn hình
- (void)clampPanel {
    if (!self.panel) return;
    CGSize v = self.view.bounds.size;
    CGSize p = self.panel.bounds.size;
    CGFloat maxX = MAX(0, (v.width - p.width) / 2);
    CGFloat maxY = MAX(0, (v.height - p.height) / 2);
    CGFloat x = MIN(MAX(self.panelCX.constant, -maxX), maxX);
    CGFloat y = MIN(MAX(self.panelCY.constant, -maxY), maxY);
    if (x != self.panelCX.constant) self.panelCX.constant = x;
    if (y != self.panelCY.constant) self.panelCY.constant = y;
}

- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
    if (!self.panel.hidden) [self.scroll flashScrollIndicators];
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.view];
    [g setTranslation:CGPointZero inView:self.view];
    g.view.center = [self clamped:CGPointMake(g.view.center.x + t.x, g.view.center.y + t.y)];
}

- (void)onItem:(UIButton *)b {
    NSDictionary *item = Items()[b.tag];
    [self setBusy:YES text:[NSString stringWithFormat:@"Đang tải “%@”…", item[@"title"]]];
    __weak MenuVC *w = self;
    DownloadAndReplace(item, ^(BOOL ok, NSString *msg) {
        [w setBusy:NO text:[(ok ? @"✅ " : @"❌ ") stringByAppendingString:msg ?: @""]];
    });
}

- (void)setBusy:(BOOL)busy text:(NSString *)text {
    for (UIButton *b in self.itemBtns) { b.enabled = !busy; b.alpha = busy ? 0.5 : 1; }
    self.status.text = text;
}

@end

#pragma mark - Khởi động

static PassthroughWindow *gWindow;

static void ShowOverlay(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:UIWindowScene.class] && s.activationState == UISceneActivationStateForegroundActive) {
                gWindow = [[PassthroughWindow alloc] initWithWindowScene:(UIWindowScene *)s];
                break;
            }
        }
    }
    if (!gWindow) gWindow = [[PassthroughWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    gWindow.windowLevel = UIWindowLevelAlert + 100;
    gWindow.backgroundColor = UIColor.clearColor;
    gWindow.rootViewController = [MenuVC new];
    gWindow.hidden = NO;   // không makeKey để không cướp input/orientation của game
}

__attribute__((constructor)) static void Init(void) {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
        queue:NSOperationQueue.mainQueue
        usingBlock:^(NSNotification *n) {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{ ShowOverlay(); });
            });
        }];
}
