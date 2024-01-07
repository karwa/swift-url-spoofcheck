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

import CUSpoof
import WebURL

/// An object which checks domain labels for possible spoofing attempts.
///
/// This checker uses a port of Chromium's IDN spoof-checking logic ([Overview][chr-over], [Implementation][chr-impl]).
/// It implements most of it, with the exception of:
///
/// - Step 10, which checks single-script labels for whole-script confusables.
/// - Step 12, which checks mixed-script labels for a number of known dangerous patterns.
/// - Step 13, which checks mixed-script labels which look confusingly similar to a database of top domains.
///
/// > Note:
/// > Access the checker via the `shared` singleton. The checker is thread-safe.
///
/// [chr-over]: https://github.com/chromium/chromium/blob/9de1b06631d03b9964c763797a0d7163e2bdfe3e/docs/idn.md#google-chromes-idn-policy
/// [chr-impl]: https://github.com/chromium/chromium/blob/927335df26c5841e6e16776b7f4545b0fe55ec95/components/url_formatter/spoof_checks
///
internal final class IDNSpoofChecker {

  // Singleton instance.
  // The UnicodeSets are frozen (immutable), and checking strings using the USpoofChecker is thread-safe.

  public static var shared: IDNSpoofChecker = { .init()! }()

  // USpoofChecker.
  private let checker: OpaquePointer
  // UnicodeSets (all frozen).
  private let kana_letters_exceptions: OpaquePointer
  private let combining_diacritics_exceptions: OpaquePointer
  private let digit_lookalikes: OpaquePointer

  private init?() {

    // === Checker ===

    var status = U_ZERO_ERROR
    checker = swift_url_uspoof_open(&status)!
    guard !status.isFailure else { return nil }

    // At this point, USpoofChecker has all the checks enabled except
    // for USPOOF_CHAR_LIMIT (USPOOF_{RESTRICTION_LEVEL, INVISIBLE,
    // MIXED_SCRIPT_CONFUSABLE, WHOLE_SCRIPT_CONFUSABLE, MIXED_NUMBERS, ANY_CASE})
    // This default configuration is adjusted below as necessary.

    // Set the restriction level to high. It allows mixing Latin with one logical
    // CJK script (+ COMMON and INHERITED), but does not allow any other script
    // mixing (e.g. Latin + Cyrillic, Latin + Armenian, Cyrillic + Greek). Note
    // that each of {Han + Bopomofo} for Chinese, {Hiragana, Katakana, Han} for
    // Japanese, and {Hangul, Han} for Korean is treated as a single logical
    // script.
    // See http://www.unicode.org/reports/tr39/#Restriction_Level_Detection
    swift_url_uspoof_setRestrictionLevel(checker, USPOOF_HIGHLY_RESTRICTIVE)

    // Sets allowed characters in IDN labels and turns on USPOOF_CHAR_LIMIT.
    IDNSpoofChecker.setAllowedCharacters(checker: checker, status: &status)
    guard !status.isFailure else { return nil }

    // Enable the return of auxillary (non-error) information.
    let checks = swift_url_uspoof_getChecks(checker, &status) | USPOOF_AUX_INFO.cValue
    swift_url_uspoof_setChecks(checker, checks, &status)
    guard !status.isFailure else { return nil }

    // === Character sets ===

    func makeSet(_ pattern: String) -> OpaquePointer? {
      var status = U_ZERO_ERROR

      let utf16Pattern = Array(pattern.utf16)
      let set = swift_url_uset_openPattern(utf16Pattern, Int32(utf16Pattern.count), &status)!
      swift_url_uset_freeze(set)

      guard !status.isFailure else { return nil }
      return set
    }

    // These characters are, or look like, digits. A domain label entirely made of
    // digit-lookalikes or digits is blocked.
    if let set = makeSet(#"[θ२২੨੨૨೩೭շзҙӡउওਤ੩૩౩ဒვპੜკ੫丩ㄐճ৪੪୫૭୨౨]"#) {
      digit_lookalikes = set
    } else {
      return nil
    }

    // The following two sets are parts of "dangerous_patterns".
    // They require extra checks, even in single-script labels.
    if let set = makeSet(#"[\u3078-\u307a\u30d8-\u30da\u30fb-\u30fe]"#) {
      kana_letters_exceptions = set
    } else {
      return nil
    }
    if let set = makeSet(#"[\u0300-\u0339]"#) {
      combining_diacritics_exceptions = set
    } else {
      return nil
    }

    // TODO: Whole-Script Confusable Data
    // TODO: Skeletons
  }

  private static func setAllowedCharacters(checker: OpaquePointer, status: inout UErrorCode) {

    let allowedChars = swift_url_uset_openEmpty()!
    defer { swift_url_uset_close(allowedChars) }

    // The recommended set is a set of characters for identifiers in a
    // security-sensitive environment taken from UTR 39
    // (http://unicode.org/reports/tr39/) and
    // http://www.unicode.org/Public/security/latest/xidmodifications.txt .
    // The inclusion set comes from "Candidate Characters for Inclusion
    // in idenfiers" of UTR 31 (http://www.unicode.org/reports/tr31).
    swift_url_uset_addAll(allowedChars, swift_url_uspoof_getRecommendedSet(&status)!)
    guard !status.isFailure else { return }

    swift_url_uset_addAll(allowedChars, swift_url_uspoof_getInclusionSet(&status)!)
    guard !status.isFailure else { return }

    // The sections below refer to Mozilla's IDN blacklist:
    // http://kb.mozillazine.org/Network.IDN.blacklist_chars
    //
    // U+0338 (Combining Long Solidus Overlay) is included in the recommended set,
    // but is blacklisted by Mozilla. It is dropped because it can look like a
    // slash when rendered with a broken font.
    swift_url_uset_remove(allowedChars, 0x0338)

    // U+05F4 (Hebrew Punctuation Gershayim) is in the inclusion set, but is
    // blacklisted by Mozilla. We keep it, even though it can look like a double
    // quotation mark. Using it in Hebrew should be safe. When used with a
    // non-Hebrew script, it'd be filtered by other checks in place.

    // The following 5 characters are disallowed because they're in NV8 (invalid
    // in IDNA 2008).
    swift_url_uset_remove(allowedChars, 0x058A)  // Armenian Hyphen
    // U+2010 (Hyphen) is in the inclusion set, but we drop it because it can be
    // confused with an ASCII U+002D (Hyphen-Minus).
    swift_url_uset_remove(allowedChars, 0x2010)
    // U+2019 is hard to notice when sitting next to a regular character.
    swift_url_uset_remove(allowedChars, 0x2019)  // Right Single Quotation Mark
    // U+2027 (Hyphenation Point) is in the inclusion set, but is blacklisted by
    // Mozilla. It is dropped, as it can be confused with U+30FB (Katakana Middle
    // Dot).
    swift_url_uset_remove(allowedChars, 0x2027)
    swift_url_uset_remove(allowedChars, 0x30A0)  // Katakana-Hiragana Double Hyphen

    // Block {Single,double}-quotation-mark look-alikes.
    swift_url_uset_remove(allowedChars, 0x02BB)  // Modifier Letter Turned Comma
    swift_url_uset_remove(allowedChars, 0x02BC)  // Modifier Letter Apostrophe

    // Block modifier letter voicing.
    swift_url_uset_remove(allowedChars, 0x02EC)

    // Block historic character Latin Kra (also blocked by Mozilla).
    swift_url_uset_remove(allowedChars, 0x0138)

    // No need to block U+144A (Canadian Syllabics West-Cree P) separately
    // because it's blocked from mixing with other scripts including Latin.

    #if canImport(Darwin)
      // The following characters are reported as present in the default macOS
      // system UI font, but they render as blank. Remove them from the allowed
      // set to prevent spoofing until the font issue is resolved.

      // Arabic letter KASHMIRI YEH. Not used in Arabic and Persian.
      swift_url_uset_remove(allowedChars, 0x0620)

      // Tibetan characters used for transliteration of ancient texts:
      swift_url_uset_remove(allowedChars, 0x0F8C)
      swift_url_uset_remove(allowedChars, 0x0F8D)
      swift_url_uset_remove(allowedChars, 0x0F8E)
      swift_url_uset_remove(allowedChars, 0x0F8F)
    #endif

    // Disallow extremely rarely used LGC character blocks.
    // Cyllic Ext A is not in the allowed set. Neither are Latin Ext-{C,E}.
    swift_url_uset_removeRange(allowedChars, 0x01CD, 0x01DC)  // Latin Ext B; Pinyin
    swift_url_uset_removeRange(allowedChars, 0x1C80, 0x1C8F)  // Cyrillic Extended-C
    swift_url_uset_removeRange(allowedChars, 0x1E00, 0x1E9B)  // Latin Extended Additional
    swift_url_uset_removeRange(allowedChars, 0x1F00, 0x1FFF)  // Greek Extended
    swift_url_uset_removeRange(allowedChars, 0xA640, 0xA69F)  // Cyrillic Extended-B
    swift_url_uset_removeRange(allowedChars, 0xA720, 0xA7FF)  // Latin Extended-D

    swift_url_uspoof_setAllowedChars(checker, allowedChars, &status)
    guard !status.isFailure else { return }
  }
}

extension IDNSpoofChecker {

  public enum CheckResult {
    case unableToRunSpoofCheck
    case spoofCheckFailed
    case tldSpecificCharacters
    case digitLookalikes
    case unsafeMiddleDot

    case safe
  }

  /// Checks whether or not it is safe to display the given label as Unicode.
  ///
  /// - parameters:
  ///   - label:          The label to check
  ///   - topLevelDomain: The top-level segment of the domain.
  ///
  /// - returns: A result indicating which (if any) checks failed.
  ///            If the result is `.safe`, the label may be displayed in Unicode.
  ///            Otherwise, it is advisable to display as Punycode or some other way.
  ///
  public func isSafeToDisplayAsUnicode(
    _ label: inout WebURL.Domain.Renderer.Label, topLevelDomain: String
  ) -> CheckResult {

    guard label.isIDN else {
      return .safe
    }

    // === USpoofChecker ===

    var status = U_ZERO_ERROR
    var mutString = label.unicode
    let icuResult = mutString.withUTF8 { utf8 in
      utf8.withMemoryRebound(to: CChar.self) { cchars in
        // Unfortunately, there is no buffer-of-scalars version of this API.
        swift_url_uspoof_checkUTF8(checker, cchars.baseAddress, Int32(cchars.count), &status)
      }
    }

    if status.isFailure {
      return .unableToRunSpoofCheck
    }
    if (icuResult & USPOOF_ALL_CHECKS.cValue) != 0 {
      return .spoofCheckFailed
    }

    let restrictionLevel = URestrictionLevel(rawValue: icuResult & USPOOF_RESTRICTION_LEVEL_MASK.rawValue)
    assert(restrictionLevel != USPOOF_ASCII, "ASCII labels should have been handled already")

    // === TLD-Specific Rules ===

    // Latin small letter thorn ("þ", U+00FE) can be used to spoof both b and p.
    // It's used in modern Icelandic orthography, so allow it for the Icelandic
    // ccTLD (.is) but block in any other TLD. Also block Latin small letter eth
    // ("ð", U+00F0) which can be used to spoof the letter o.
    if topLevelDomain != "is" {
      if label.unicodeScalars.contains("þ") || label.unicodeScalars.contains("ð") {
        return .tldSpecificCharacters
      }
    }

    // Disallow Latin Schwa (U+0259) for domains outside Azerbaijan's ccTLD (.az).
    if topLevelDomain != "az" {
      if label.unicodeScalars.contains("ə") {
        return .tldSpecificCharacters
      }
    }

    // Disallow middle dot (U+00B7) when unsafe.
    if hasUnsafeMiddleDot(label.unicodeScalars, topLevelDomain: topLevelDomain) {
      return .unsafeMiddleDot
    }

    // === Other Checks ===

    // Disallow domains that contain only numbers and number-spoofs.
    if hasDigitLookalike(label.unicodeScalars) {
      return .digitLookalikes
    }

    // === Single-Script ===

    singlescript: if restrictionLevel == USPOOF_SINGLE_SCRIPT_RESTRICTIVE {
      // If there's no script mixing, the input is regarded as safe without any
      // extra check unless it falls into one of three categories:
      //   - contains Kana letter exceptions
      //   - it has combining diacritic marks.
      //   - the TLD is ASCII and the input is made entirely of whole script
      //     characters confusable that look like Latin letters.
      // Note that the following combinations of scripts are treated as a 'logical'
      // single script.
      //  - Chinese: Han, Bopomofo, Common
      //  - Japanese: Han, Hiragana, Katakana, Common
      //  - Korean: Hangul, Han, Common
      if label.unicodeScalars.containsAnyFromICUSet(kana_letters_exceptions) {
        break singlescript
      }
      if label.unicodeScalars.containsAnyFromICUSet(combining_diacritics_exceptions) {
        break singlescript
      }

      // TODO: Whole-Script Confusables.

      return .safe
    }

    // === Mixed Scripts ===

    // TODO: Additional checks for mixed scripts.

    return .safe
  }


  /// Returns true if the label contains a digit lookalike, and all other characters are ASCII digits.
  ///
  private func hasDigitLookalike(_ scalars: [Unicode.Scalar]) -> Bool {

    var hasLookalike = false
    for scalar in scalars {
      if ("0"..."9").contains(scalar) {
        continue
      }
      if swift_url_uset_contains(digit_lookalikes, Int32(bitPattern: scalar.value)) != 0 {
        hasLookalike = true
      } else {
        return false
      }
    }
    return hasLookalike
  }

  /// Returns true if the label contains a middle dot (U+00B7), except if the dot is between two 'l's
  /// and the TLD is Catalan.
  ///
  /// See https://tools.ietf.org/html/rfc5892#appendix-A.3 for details.
  ///
  private func hasUnsafeMiddleDot(_ scalars: [Unicode.Scalar], topLevelDomain: String) -> Bool {

    var hasMiddleDot = false
    var start = scalars.startIndex
    while let middleDot = scalars[start...].firstIndex(of: "·") {
      // Middle dot must have a character before and after it.
      guard middleDot > scalars.startIndex, middleDot &+ 1 < scalars.endIndex else {
        return true
      }
      // And those characters must both be "l"
      guard scalars[middleDot &- 1] == "l", scalars[middleDot &+ 1] == "l" else {
        return true
      }
      hasMiddleDot = true
      start = middleDot &+ 1
    }

    // Even betwen two 'l's, middle dots are only allowed in Catalan domains.
    return hasMiddleDot && topLevelDomain != "cat"
  }
}

#if swift(>=5.5) && canImport(_Concurrency)
  extension IDNSpoofChecker: @unchecked Sendable {}
#endif
