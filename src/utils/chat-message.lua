local strlen = string.len
local CS = CHAT_SYSTEM

local MAX_CHAT_MESSAGE_LENGTH = 1500
local MSG_TOO_LONG = "Message was too long to submit"

PanicidaChatMessage = ZO_Object:Subclass()

function PanicidaChatMessage:New(prefix)
    local instance = ZO_Object.New(self)
    instance:Initialize(prefix)
    return instance
end

function PanicidaChatMessage:Initialize(prefix)
    self.prefix = prefix or ""
    self.maxCharacters = MAX_CHAT_MESSAGE_LENGTH
    self.buffer = {}
    self.bufferIndex = 0

    self:_AddBufferEntry("")
end

function PanicidaChatMessage:_AddBufferEntry(text)
    self.bufferIndex = self.bufferIndex + 1
    self.buffer[self.bufferIndex] = text
end

function PanicidaChatMessage:AddMessage(message)
    if not message or message == "" then return end

    local currentIndex = self.bufferIndex
    local currentText = self.buffer[currentIndex]
    local currentLength = strlen(currentText)
    local messageLength = strlen(message)
    local maxChars = self.maxCharacters
    local availableSpace = maxChars - currentLength

    if messageLength <= availableSpace then
        self.buffer[currentIndex] = currentText .. message
    elseif messageLength <= maxChars then
        self:_AddBufferEntry(message)
    else
        self:_AddBufferEntry(MSG_TOO_LONG)
        self:_AddBufferEntry("")
    end
end

function PanicidaChatMessage:Submit()
    if self.bufferIndex == 0 or (self.bufferIndex == 1 and self.buffer[1] == "") then
        return
    end

    local prefix = self.prefix

    for i = 1, self.bufferIndex do
        local message = self.buffer[i]
        if message and message ~= "" then
            CS:AddMessage(prefix .. message)
        end
    end

    self:Reset()
end

function PanicidaChatMessage:Reset()
    self.buffer = {}
    self.bufferIndex = 0
    self:_AddBufferEntry("")
end
