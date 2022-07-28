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

import XCTest
import WebURL
@testable import WebURLSpoofCheck

final class SpoofCheckedRendererTests: XCTestCase {

    func testBasic() throws {

      let domains: [(input: String, unchecked: String, checked: String)] = [

        ("example.com", "example.com", "example.com"),
        ("你好你好", "你好你好", "你好你好"),
        ("a.أهلا.com", "a.أهلا.com", "a.أهلا.com"),

        // Emoji are not allowed :( Yes, Chrome really blocks them.
        ("😀.com", "😀.com", "xn--e28h.com"),
        ("☃", "☃", "xn--n3h"),

        // Some basic spoofs.
        ("раγpal.com", "раγpal.com", "xn--pal-vxc83d5c.com"),
        ("аpple.com", "аpple.com", "xn--pple-43d.com"),

        // Deviation characters. We allow them, Chrome doesn't.
        ("faß.ExAmPlE", "faß.example", "faß.example"),

        // Allowed for Icelandic TLD only.
        ("some-hosþital.com", "some-hosþital.com", "xn--some-hosital-bmb.com"),
        ("some-hosþital.is", "some-hosþital.is", "some-hosþital.is"),
        // Allowed for Azerbaijani TLD only.
        ("əpple.com", "əpple.com", "xn--pple-u6b.com"),
        ("əpple.az", "əpple.az", "əpple.az"),
        // Middle dots. Only allowed between two 'l's, and only for Catalan TLD.
        ("example·com", "example·com", "xn--examplecom-rra"),
        ("example·com.cat", "example·com.cat", "xn--examplecom-rra.cat"),
        ("·example.cat", "·example.cat", "xn--example-uma.cat"),
        ("example·.cat", "example·.cat", "xn--example-1ma.cat"),
        ("pel··lícula.cat", "pel··lícula.cat", "xn--pellcula-ioaa90d.cat"),
        ("pe·l·lícula.cat", "pe·l·lícula.cat", "xn--pellcula-hoab90d.cat"),
        ("pel·l·ícula.cat", "pel·l·ícula.cat", "xn--pellcula-ioab80d.cat"),

        ("pel·lícula.cat", "pel·lícula.cat", "pel·lícula.cat"),
        ("pel·lícula.com", "pel·lícula.com", "xn--pellcula-ioa55c.com"),

        // Digit lookalike.
        ("xn--16-1ik.com", "16კ.com", "xn--16-1ik.com"),
      ]

      for (input, expectedUnchecked, expectedChecked) in domains {
        let domain = WebURL.Domain(input)!

        let actualUnchecked = domain.render(.uncheckedUnicodeString)
        let actualChecked = domain.render(.checkedUnicodeString)
        XCTAssertEqual(actualUnchecked, expectedUnchecked)
        XCTAssertEqual(actualChecked, expectedChecked)

        print("================")
        print("ASCII: \(domain)")
        print("Unchecked: \(actualUnchecked)")
        print("Checked: \(actualChecked)")
        print("================")
      }
    }
}
