require "sumitsubo"
# Written by scripts/vendor.sh and not committed, so only the executable can
# reach it — which is what keeps a stamped revision out of every test.
require "build_rev"

exit Sumitsubo::CLI.new(Sumitsubo::STAMPED_REV).run(ARGV)
