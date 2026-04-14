# Requirements Document

## Introduction

This feature filters out keywords that a user has already marked as "known" from the list of keywords returned during session preparation. When the LLM generates keywords for a Quran passage, the system fetches the user's previously known keywords from DynamoDB and removes any matches before returning the keyword list. This ensures users only see new or unfamiliar vocabulary, improving the study experience.

## Glossary

- **Prepare_Session_Handler**: The handler for `POST /sessions/prepare` that fetches Quran content, invokes the LLM, and returns an overview and keyword list to the user
- **Known_Keywords_Store**: The set of DynamoDB items with sort key prefix `KEYWORD#` under a user's partition key (`USER#{userId}`), representing keywords the user has previously marked as known
- **LLM_Keywords**: The list of up to 20 keywords returned by the Bedrock model during session preparation, each containing an Arabic word, translation, hint, and type
- **Keyword_Filter**: The component that removes known keywords from the LLM-generated keyword list before returning it to the user
- **DynamoDB_Table**: The single-table DynamoDB resource used for all data persistence

## Requirements

### Requirement 1: Fetch Known Keywords During Session Preparation

**User Story:** As a user, I want the system to retrieve my previously known keywords when I start a new session, so that the system can avoid showing me vocabulary I already know.

#### Acceptance Criteria

1. WHEN a user calls `POST /sessions/prepare`, THE Prepare_Session_Handler SHALL query the Known_Keywords_Store for all keywords belonging to the authenticated user
2. THE Prepare_Session_Handler SHALL query the DynamoDB_Table using the partition key `USER#{userId}` and sort key prefix `KEYWORD#` to retrieve the Known_Keywords_Store
3. IF the DynamoDB_Table query for known keywords fails, THEN THE Prepare_Session_Handler SHALL log the error and continue with an empty known keywords list, returning the full unfiltered LLM_Keywords to the user

### Requirement 2: Filter Known Keywords from LLM Response

**User Story:** As a user, I want keywords I have already marked as known to be excluded from the keyword list, so that I only study vocabulary that is new or unfamiliar to me.

#### Acceptance Criteria

1. WHEN the LLM returns LLM_Keywords, THE Keyword_Filter SHALL remove any keyword whose Arabic text matches an entry in the user's Known_Keywords_Store
2. THE Keyword_Filter SHALL compare keywords using exact string matching on the `arabic` field
3. WHEN known keywords are removed, THE Prepare_Session_Handler SHALL return only the remaining keywords to the user
4. WHEN all LLM_Keywords match entries in the Known_Keywords_Store, THE Prepare_Session_Handler SHALL return an empty keywords array

### Requirement 3: Preserve Keyword Ordering and Limit

**User Story:** As a user, I want the filtered keyword list to maintain the original importance ranking from the LLM, so that I see the most relevant unfamiliar keywords first.

#### Acceptance Criteria

1. THE Keyword_Filter SHALL preserve the original ordering of LLM_Keywords after removing known keywords
2. THE Prepare_Session_Handler SHALL return at most 20 keywords after filtering
3. WHEN filtering reduces the keyword count below 20, THE Prepare_Session_Handler SHALL return all remaining keywords without padding or backfilling

### Requirement 4: No Impact on Session Creation Keyword Storage

**User Story:** As a developer, I want the known keyword filtering to be independent of the existing keyword storage logic in session creation, so that the two features do not interfere with each other.

#### Acceptance Criteria

1. WHEN a session is created via `POST /sessions`, THE Prepare_Session_Handler SHALL continue to store keywords marked as "known" in the Known_Keywords_Store using the existing `KEYWORD#{arabic}` sort key pattern
2. THE Keyword_Filter SHALL operate only during session preparation and SHALL NOT modify or delete entries in the Known_Keywords_Store
