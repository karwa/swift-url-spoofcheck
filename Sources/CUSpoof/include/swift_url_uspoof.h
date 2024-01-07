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

#ifndef SWIFT_URL_USPOOF_h
#define SWIFT_URL_USPOOF_h

#include <unicode/uspoof.h>

// USet APIs.

typedef struct USet USet;

USet* swift_url_uset_openEmpty();
USet* swift_url_uset_openPattern(const UChar* pattern, int32_t length, UErrorCode* status);
void swift_url_uset_close(USet* set);
void swift_url_uset_freeze(USet* set);
inline UBool swift_url_uset_contains(USet* set, UChar32 codepoint);

void swift_url_uset_addAll(USet* set, USet* otherSet);
void swift_url_uset_remove(USet* set, UChar32 codepoint);
void swift_url_uset_removeRange(USet* set, UChar32 start, UChar32 end);

// USpoof APIs.

typedef struct USpoofChecker USpoofChecker;

USpoofChecker* swift_url_uspoof_open(UErrorCode* status);

int32_t swift_url_uspoof_getChecks(USpoofChecker * sc, UErrorCode* status);
void swift_url_uspoof_setChecks(USpoofChecker * sc, int32_t checks, UErrorCode* status);

void swift_url_uspoof_setRestrictionLevel(USpoofChecker * sc, URestrictionLevel level);
void swift_url_uspoof_setAllowedChars(USpoofChecker * sc, USet * allowedChars, UErrorCode* status);

const USet* swift_url_uspoof_getRecommendedSet(UErrorCode* status);
const USet* swift_url_uspoof_getInclusionSet(UErrorCode* status);

int32_t swift_url_uspoof_checkUTF8(USpoofChecker * sc, const char * string, int32_t stringLength, UErrorCode* status);

#endif /* SWIFT_URL_USPOOF_h */
