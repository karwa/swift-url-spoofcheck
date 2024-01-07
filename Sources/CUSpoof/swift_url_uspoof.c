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

#include "swift_url_uspoof.h"

// USet APIs.

USet* swift_url_uset_openEmpty() {
  return uset_openEmpty();
}

USet* swift_url_uset_openPattern(const UChar* pattern, int32_t length, UErrorCode* status) {
  return uset_openPattern(pattern, length, status);
}

void swift_url_uset_close(USet* set) {
  uset_close(set);
}

void swift_url_uset_freeze(USet* set) {
  uset_freeze(set);
}

UBool swift_url_uset_contains(USet* set, UChar32 codepoint) {
  return uset_contains(set, codepoint);
}

void swift_url_uset_addAll(USet* set, USet* otherSet) {
  uset_addAll(set, otherSet);
}

void swift_url_uset_remove(USet* set, UChar32 codepoint) {
  uset_remove(set, codepoint);
}

void swift_url_uset_removeRange(USet* set, UChar32 start, UChar32 end) {
  uset_removeRange(set, start, end);
}

// USpoof APIs.

USpoofChecker* swift_url_uspoof_open(UErrorCode* status) {
  return uspoof_open(status);
}

int32_t swift_url_uspoof_getChecks(USpoofChecker * sc, UErrorCode* status) {
  return uspoof_getChecks(sc, status);
}

void swift_url_uspoof_setChecks(USpoofChecker * sc, int32_t checks, UErrorCode* status) {
  return uspoof_setChecks(sc, checks, status);
}

void swift_url_uspoof_setRestrictionLevel(USpoofChecker * sc, URestrictionLevel level) {
  return uspoof_setRestrictionLevel(sc, level);
}

void swift_url_uspoof_setAllowedChars(USpoofChecker * sc, USet * allowedChars, UErrorCode* status) {
  return uspoof_setAllowedChars(sc, allowedChars, status);
}

int32_t swift_url_uspoof_checkUTF8(USpoofChecker * sc, const char * string, int32_t stringLength, UErrorCode* status) {
  return uspoof_checkUTF8(sc, string, stringLength, NULL, status);
}

const USet* swift_url_uspoof_getRecommendedSet(UErrorCode* status) {
  return uspoof_getRecommendedSet(status);
}

const USet* swift_url_uspoof_getInclusionSet(UErrorCode* status) {
  return uspoof_getInclusionSet(status);
}
