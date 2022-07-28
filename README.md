# WebURLSpoofChecking

A proof-of-concept `WebURL.Domain` renderer which uses a port of Chromium's IDN spoof-checking logic ([Overview][chr-over], [Implementation][chr-impl])
to protect against confusable domains. It implements most of Chromium's logic, with the exception of:

- Step 10, which checks single-script labels for whole-script confusables.
- Step 12, which checks mixed-script labels for a number of known dangerous patterns.
- Step 13, which checks mixed-script labels which look confusingly similar to a database of top domains.

```swift
// Non-spoofs are allowed.
// It doesn't just reject all Unicode 😅

WebURL.Domain("example.com")?.render(.checkedUnicodeString) // ✅ "example.com"
WebURL.Domain("a.أهلا.com")?.render(.checkedUnicodeString)   // ✅ "a.أهلا.com"
WebURL.Domain("你好你好")?.render(.checkedUnicodeString)     // ✅ "你好你好"

// But it does catch some actual spoofs, too.
// These are not the domains they might look like.

WebURL.Domain("раγpal.com")?.render(.checkedUnicodeString) // ✅ "xn--pal-vxc83d5c.com"
WebURL.Domain("аpple.com")?.render(.checkedUnicodeString)  // ✅ "xn--pple-43d.com"
WebURL.Domain("16კ.com")?.render(.checkedUnicodeString)    // ✅ "xn--16-1ik.com"
        
// Sometimes this includes specific rules for particular TLDs,
// such as only allowing "ə" (Latin Schwa, U+0259) in Azerbaijani domains

WebURL.Domain("əpple.com")?.render(.checkedUnicodeString)  // ✅ "xn--pple-u6b.com"
WebURL.Domain("əpple.az")?.render(.checkedUnicodeString)   // ✅ "əpple.az"
```

[chr-over]: https://github.com/chromium/chromium/blob/9de1b06631d03b9964c763797a0d7163e2bdfe3e/docs/idn.md#google-chromes-idn-policy
[chr-impl]: https://github.com/chromium/chromium/blob/927335df26c5841e6e16776b7f4545b0fe55ec95/components/url_formatter/spoof_checks
