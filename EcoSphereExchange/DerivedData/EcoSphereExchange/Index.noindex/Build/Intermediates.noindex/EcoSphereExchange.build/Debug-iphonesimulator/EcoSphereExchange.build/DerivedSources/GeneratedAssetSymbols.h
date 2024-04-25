#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"VividVentures.EcoSphereExchange";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "LuLu" asset catalog image resource.
static NSString * const ACImageNameLuLu AC_SWIFT_PRIVATE = @"LuLu";

/// The "Product.1" asset catalog image resource.
static NSString * const ACImageNameProduct1 AC_SWIFT_PRIVATE = @"Product.1";

/// The "Zpp.img" asset catalog image resource.
static NSString * const ACImageNameZppImg AC_SWIFT_PRIVATE = @"Zpp.img";

/// The "img" asset catalog image resource.
static NSString * const ACImageNameImg AC_SWIFT_PRIVATE = @"img";

/// The "img.2" asset catalog image resource.
static NSString * const ACImageNameImg2 AC_SWIFT_PRIVATE = @"img.2";

/// The "img.5" asset catalog image resource.
static NSString * const ACImageNameImg5 AC_SWIFT_PRIVATE = @"img.5";

/// The "img.9" asset catalog image resource.
static NSString * const ACImageNameImg9 AC_SWIFT_PRIVATE = @"img.9";

/// The "img.g" asset catalog image resource.
static NSString * const ACImageNameImgG AC_SWIFT_PRIVATE = @"img.g";

/// The "img.g2" asset catalog image resource.
static NSString * const ACImageNameImgG2 AC_SWIFT_PRIVATE = @"img.g2";

/// The "img.g3" asset catalog image resource.
static NSString * const ACImageNameImgG3 AC_SWIFT_PRIVATE = @"img.g3";

/// The "img4" asset catalog image resource.
static NSString * const ACImageNameImg4 AC_SWIFT_PRIVATE = @"img4";

/// The "product picture (1)" asset catalog image resource.
static NSString * const ACImageNameProductPicture1 AC_SWIFT_PRIVATE = @"product picture (1)";

#undef AC_SWIFT_PRIVATE
