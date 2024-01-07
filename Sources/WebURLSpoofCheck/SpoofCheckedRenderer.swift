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

import WebURL

/// A `WebURL.Domain.Renderer` which checks for confusable Unicode labels.
///
public struct SpoofCheckedRenderer: WebURL.Domain.Renderer {

  public var result = ""
  private var _topLevelDomain: Optional<String> = .none

  public mutating func processLabel(_ label: inout Label, isEnd: Bool) {

    let tld: String

    if let topLevelDomain = _topLevelDomain {
      tld = topLevelDomain
    } else {
      if result.isEmpty, label.ascii.isEmpty {
        // Rightmost label is empty. This is a Fully-Qualified Domain Name (FQDN).
        result = "."
        return
      }
      tld = label.isIDN ? String(label.unicode) : String(label.ascii)
      self._topLevelDomain = tld
    }

    guard label.isIDN else {
      result.insert(contentsOf: label.asciiWithLeadingDelimiter, at: result.startIndex)
      return
    }
    switch IDNSpoofChecker.shared.isSafeToDisplayAsUnicode(&label, topLevelDomain: tld) {
    case .safe:
      result.insert(contentsOf: label.unicode, at: result.startIndex)
      if !isEnd { result.insert(".", at: result.startIndex) }
    default:
      result.insert(contentsOf: label.asciiWithLeadingDelimiter, at: result.startIndex)
    }
  }
}

extension WebURL.Domain.Renderer where Self == SpoofCheckedRenderer {

  public static var checkedUnicodeString: SpoofCheckedRenderer { .init() }
}


