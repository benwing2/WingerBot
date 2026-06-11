local tests = require("Module:UnitTests")
local driver = require("Module:User:Benwing2/run-lua/is-IPA/testcases/driver")

local examples = require("Module:User:Benwing2/run-lua/is-IPA/testcases/data").testcases

function tests:check_ipa(respelling, spelling, expected, gloss, dialect, comment)
	return driver.check_ipa(self, respelling, spelling, expected, gloss, dialect, comment)
end

function tests:test()
	self:iterate(driver.parse(examples), "check_ipa")
end

return tests
