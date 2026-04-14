//
//  Environment+Brand.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 14/04/26.
//

import SwiftUI

public struct AppBrandKey: EnvironmentKey {
    public static let defaultValue: AppBrand = GenericBrand()
}

public extension EnvironmentValues {
    var brand: AppBrand {
        get { self[AppBrandKey.self] }
        set { self[AppBrandKey.self] = newValue }
    }
}
