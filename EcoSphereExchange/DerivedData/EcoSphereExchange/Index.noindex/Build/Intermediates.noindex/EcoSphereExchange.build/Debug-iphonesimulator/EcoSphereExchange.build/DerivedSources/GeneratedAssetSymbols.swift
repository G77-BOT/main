import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "LuLu" asset catalog image resource.
    static let luLu = DeveloperToolsSupport.ImageResource(name: "LuLu", bundle: resourceBundle)

    /// The "Product.1" asset catalog image resource.
    static let product1 = DeveloperToolsSupport.ImageResource(name: "Product.1", bundle: resourceBundle)

    /// The "Zpp.img" asset catalog image resource.
    static let zppImg = DeveloperToolsSupport.ImageResource(name: "Zpp.img", bundle: resourceBundle)

    /// The "img" asset catalog image resource.
    static let img = DeveloperToolsSupport.ImageResource(name: "img", bundle: resourceBundle)

    /// The "img.2" asset catalog image resource.
    static let img2 = DeveloperToolsSupport.ImageResource(name: "img.2", bundle: resourceBundle)

    /// The "img.5" asset catalog image resource.
    static let img5 = DeveloperToolsSupport.ImageResource(name: "img.5", bundle: resourceBundle)

    /// The "img.9" asset catalog image resource.
    static let img9 = DeveloperToolsSupport.ImageResource(name: "img.9", bundle: resourceBundle)

    /// The "img.g" asset catalog image resource.
    static let imgG = DeveloperToolsSupport.ImageResource(name: "img.g", bundle: resourceBundle)

    /// The "img.g2" asset catalog image resource.
    static let imgG2 = DeveloperToolsSupport.ImageResource(name: "img.g2", bundle: resourceBundle)

    /// The "img.g3" asset catalog image resource.
    static let imgG3 = DeveloperToolsSupport.ImageResource(name: "img.g3", bundle: resourceBundle)

    /// The "img4" asset catalog image resource.
    static let img4 = DeveloperToolsSupport.ImageResource(name: "img4", bundle: resourceBundle)

    /// The "product picture (1)" asset catalog image resource.
    static let productPicture1 = DeveloperToolsSupport.ImageResource(name: "product picture (1)", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "LuLu" asset catalog image.
    static var luLu: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .luLu)
#else
        .init()
#endif
    }

    /// The "Product.1" asset catalog image.
    static var product1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .product1)
#else
        .init()
#endif
    }

    /// The "Zpp.img" asset catalog image.
    static var zppImg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .zppImg)
#else
        .init()
#endif
    }

    /// The "img" asset catalog image.
    static var img: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .img)
#else
        .init()
#endif
    }

    /// The "img.2" asset catalog image.
    static var img2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .img2)
#else
        .init()
#endif
    }

    /// The "img.5" asset catalog image.
    static var img5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .img5)
#else
        .init()
#endif
    }

    /// The "img.9" asset catalog image.
    static var img9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .img9)
#else
        .init()
#endif
    }

    /// The "img.g" asset catalog image.
    static var imgG: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imgG)
#else
        .init()
#endif
    }

    /// The "img.g2" asset catalog image.
    static var imgG2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imgG2)
#else
        .init()
#endif
    }

    /// The "img.g3" asset catalog image.
    static var imgG3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imgG3)
#else
        .init()
#endif
    }

    /// The "img4" asset catalog image.
    static var img4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .img4)
#else
        .init()
#endif
    }

    /// The "product picture (1)" asset catalog image.
    static var productPicture1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .productPicture1)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "LuLu" asset catalog image.
    static var luLu: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .luLu)
#else
        .init()
#endif
    }

    /// The "Product.1" asset catalog image.
    static var product1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .product1)
#else
        .init()
#endif
    }

    /// The "Zpp.img" asset catalog image.
    static var zppImg: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .zppImg)
#else
        .init()
#endif
    }

    /// The "img" asset catalog image.
    static var img: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .img)
#else
        .init()
#endif
    }

    /// The "img.2" asset catalog image.
    static var img2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .img2)
#else
        .init()
#endif
    }

    /// The "img.5" asset catalog image.
    static var img5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .img5)
#else
        .init()
#endif
    }

    /// The "img.9" asset catalog image.
    static var img9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .img9)
#else
        .init()
#endif
    }

    /// The "img.g" asset catalog image.
    static var imgG: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imgG)
#else
        .init()
#endif
    }

    /// The "img.g2" asset catalog image.
    static var imgG2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imgG2)
#else
        .init()
#endif
    }

    /// The "img.g3" asset catalog image.
    static var imgG3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imgG3)
#else
        .init()
#endif
    }

    /// The "img4" asset catalog image.
    static var img4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .img4)
#else
        .init()
#endif
    }

    /// The "product picture (1)" asset catalog image.
    static var productPicture1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .productPicture1)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: String, bundle: Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: String, bundle: Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

