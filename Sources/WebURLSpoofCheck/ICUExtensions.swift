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

import USpoof

extension UErrorCode {

  // https://github.com/unicode-org/icu/blob/c258f3d6f81a2514b76d72c5deae8cbc295aecd6/icu4c/source/common/unicode/utypes.h#L717
  internal var isFailure: Bool {
    rawValue > U_ZERO_ERROR.rawValue
  }
}

// The importer decides the raw value should be UInt32, but the rest of the API uses Int32 for `USpoofChecks` values.

extension USpoofChecks {

  internal init(cValue: Int32) {
    self.init(rawValue: UInt32(bitPattern: cValue))
  }

  internal var cValue: Int32 {
    Int32(bitPattern: rawValue)
  }
}

extension Sequence where Element == Unicode.Scalar {

  /// Whether any of this sequence's scalars are contained in the given Unicode set.
  ///
  /// `set` must be an ICU `USet` object.
  ///
  func containsAnyFromICUSet(_ set: OpaquePointer) -> Bool {
    contains(where: { uset_contains_70(set, Int32(bitPattern: $0.value)) != 0 })
  }
}
