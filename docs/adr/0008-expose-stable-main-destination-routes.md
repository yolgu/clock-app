# Expose stable routes for the main destinations

Clock, Calendar, Data, and Theme will be addressable as `/clock`, `/calendar?date=YYYY-MM-DD`, `/data`, and `/theme` through a state-restorable `go_router` shell. Each branch preserves its presentation state, Android back navigation returns from a secondary destination to Clock before exiting, and malformed dates or unknown locations produce an explicit error route rather than silently changing meaning.
