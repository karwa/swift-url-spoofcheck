// swift-tools-version:5.5

// Copyright The swift-url Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

let package = Package(
  name: "swift-url-spoofcheck",
  products: [
    .library(name: "WebURLSpoofCheck", targets: ["WebURLSpoofCheck"]),
  ],
  dependencies: [
    .package(url: "https://github.com/karwa/swift-url.git", .upToNextMinor(from: "0.4.0")),
//    .package(name: "swift-url", path: "../swift-url"),
  ],
  targets: [
    .systemLibrary(
      name: "USpoof",
      pkgConfig: "icu-i18n",
      providers: [
        .brewItem(["icu4c"]),
        .aptItem(["libicu-dev"])
      ]
    ),
    .target(
      name: "WebURLSpoofCheck",
      dependencies: [
        .target(name: "USpoof"),
        .product(name: "WebURL", package: "swift-url")
      ]
    ),
    .testTarget(
      name: "WebURLSpoofCheckTests",
      dependencies: [
        "WebURLSpoofCheck",
        .product(name: "WebURL", package: "swift-url")
      ]
    ),
  ]
)
