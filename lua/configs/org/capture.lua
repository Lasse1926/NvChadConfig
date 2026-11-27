-- Org capture templates (used by configs/org/orgmode.lua as org_capture_templates).
-- Key = the letter you press in the capture menu.

return {
  t = {
    description = "Todo",
    template = "* TODO %?\n  %u",
    target = "~/orgfiles/refile.org",
    headline = "Todo",
  },
  d = {
    description = "Daily",
    template = "* TODO %?\n  SCHEDULED: %t \n  %u",
    target = "~/orgfiles/refile.org",
    headline = "Daily",
  },
  a = {
    description = "Appointment",
    template = "* %?\n  %^T",
    target = "~/orgfiles/refile.org",
    headline = "Schedule",
  },
  s = {
    description = "Ticket state",
    template = "- %?",
    target = "~/orgfiles/ticketState.org",
    datetree = true,
  },
}
