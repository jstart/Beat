//
//  BeatPluginUI.h
//  Beat
//
//  Created by Lauri-Matti Parppei on 4.4.2023.
//  Copyright © 2023 Lauri-Matti Parppei. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IOS
#import "BeatPluginUIView.h"
#import "BeatPluginUIButton.h"
#import "BeatPluginUIDropdown.h"
#import "BeatPluginUIView.h"
#import "BeatPluginUICheckbox.h"
#import "BeatPluginUILabel.h"
#import "BeatPluginUITextField.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BeatPluginUI : NSObject

#if !TARGET_OS_IOS
- (BeatPluginUIButton*)button:(NSString*)name action:(JSValue*)action frame:(NSRect)frame;
- (BeatPluginUIDropdown*)dropdown:(nonnull NSArray<NSString *> *)items action:(JSValue*)action frame:(NSRect)frame;
- (BeatPluginUICheckbox*)checkbox:(NSString*)title action:(JSValue*)action frame:(NSRect)frame;
- (BeatPluginUILabel*)label:(NSString*)title frame:(NSRect)frame color:(NSString*)color size:(CGFloat)size font:(NSString*)fontName;
- (BeatPluginUITextField*)textField:(NSString*)title frame:(NSRect)frame action:(JSValue*)action color:(NSString*)color size:(CGFloat)size font:(NSString*)fontName;
#endif

@end

NS_ASSUME_NONNULL_END
