title:	Handle very short rests
state:	OPEN
author:	clockworkpc
labels:	
comments:	0
assignees:	
projects:	
milestone:	
number:	53
--
WHEN restSeconds = 3 seconds
AND workSeconds = x seconds
THEN play both startWorkout and end-of-rest countdown SFX simultaneously.

WHEN restSeconds < 3 seconds
DO NOT play end-of-workout SFX

WHEN restSeconds = 2 seconds
AND workSeconds = x seconds
THEN start 3-second end-of-rest countdown at x-1 second mark of workSeconds.

WHEN restSeconds = 1 second
AND workSeconds = x seconds
THEN start 3-second end-of-rest countdown at x-2 second mark of workSeconds.

WHEN restSeconds = 0 seconds
AND workSeconds = x seconds
THEN start 3-second end-of-rest countdown at x-3 second mark of workSeconds.

