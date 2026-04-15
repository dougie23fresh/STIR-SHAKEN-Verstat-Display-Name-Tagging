M = {}

------------------------------------------------------------------------
-- Verstat -> display name suffix mapping (STIR/SHAKEN)
------------------------------------------------------------------------
local verstat_suffix = {
    ["TN-Validation-Passed"] = "(Verified)",
    ["TN-Validation-Failed"] = "(Scam Likely)",
    ["No-TN-Validation"]     = "(Unverified)"
}

------------------------------------------------------------------------
-- Helper: Append a suffix to the display name of a given header.
-- If no display name exists, inject the suffix as one. Skips work
-- if the suffix is already present (idempotent).
------------------------------------------------------------------------
local function tag_header_display_name(msg, header_name, suffix)
    local value = msg:getHeader(header_name)
    if not value then return end

    local display_name = string.match(value, '^%s*"([^"]*)"')
    local new_value

    if display_name then
        if string.find(display_name, suffix, 1, true) then
            return
        end
        local new_display = display_name .. " " .. suffix
        new_value = string.gsub(value,
            '^(%s*)"[^"]*"',
            '%1"' .. new_display .. '"', 1)
    else
        new_value = string.gsub(value,
            '^(%s*)(<?sip:)',
            '%1"' .. suffix .. '" %2', 1)
    end

    msg:removeHeader(header_name)
    msg:addHeader(header_name, new_value)
end

------------------------------------------------------------------------
-- Helper: Apply a STIR/SHAKEN verstat suffix to the display names of
-- both the P-Asserted-Identity and From headers based on the verstat
-- parameter in P-Asserted-Identity. Missing/unknown verstat defaults
-- to "(Unverified)".
------------------------------------------------------------------------
local function apply_verstat_to_display_name(msg)
    local pai = msg:getHeader("P-Asserted-Identity")
    if not pai then return end

    -- Match verstat whether it sits inside the URI (before @) or as a
    -- header parameter (after the closing >).
    local verstat = string.match(pai, "verstat=([%w%-]+)")

    local suffix = verstat_suffix[verstat] or "(Unverified)"

    -- Tag both PAI and From with the suffix
    tag_header_display_name(msg, "P-Asserted-Identity", suffix)
    tag_header_display_name(msg, "From", suffix)
end

------------------------------------------------------------------------
-- Main inbound INVITE handler
------------------------------------------------------------------------
function M.inbound_INVITE(msg)
    apply_verstat_to_display_name(msg)
end

return M
