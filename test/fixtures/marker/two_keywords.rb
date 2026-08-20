# Two kinds of claim in one file, read in one pass. The route carries the space
# a list reading would have split on, which is why what follows a keyword is
# handed back unread.
# @command verify
# @route GET /users/:id
puts "claimed"

# @command
puts "a keyword with nothing after it"
