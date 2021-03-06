ModifierStateHandler = require './modifier-state-handler'
{charCodeFromKeyIdentifier, charCodeToKeyIdentifier} = require './helpers'

class KeyMapper
  translationTable: null
  modifierStateHandler: null

  destroy: ->
    @translationTable = null
    @modifierStateHandler = null

  setModifierStateHandler: (modifierStateHandler) ->
    @modifierStateHandler = modifierStateHandler

  setKeymap: (keymap) ->
    @translationTable = keymap

  getKeymap: ->
    return @translationTable

  translateKeyBinding: (event) ->
    identifier = charCodeFromKeyIdentifier(event.keyIdentifier)
    charCode = null
    if @translationTable? && identifier? && @translationTable[identifier]? && @modifierStateHandler?
      if translation = @translationTable[identifier]
        if translation.altshifted? && @modifierStateHandler.isShift() && @modifierStateHandler.isAltGr()
          charCode = translation.altshifted
          Object.defineProperty(event, 'altKey', get: -> false)
          Object.defineProperty(event, 'ctrlKey', get: -> false)
          Object.defineProperty(event, 'shiftKey', get: -> false)
        else if translation.shifted? && @modifierStateHandler.isShift()
          charCode = translation.shifted
          Object.defineProperty(event, 'shiftKey', get: -> false)
        else if translation.alted? && @modifierStateHandler.isAltGr()
          charCode = translation.alted
          Object.defineProperty(event, 'altKey', get: -> false)
          Object.defineProperty(event, 'ctrlKey', get: -> false)
        else if translation.unshifted?
          charCode = translation.unshifted

    if charCode?
      Object.defineProperty(event, 'keyIdentifier', get: -> charCodeToKeyIdentifier(charCode))
      Object.defineProperty(event, 'keyCode', get: -> charCode)
      Object.defineProperty(event, 'which', get: -> charCode)
      unless translation.accent
        event.preventDefault()

  remap: (event) ->
    @translateKeyBinding(event)

keyMapper = null

getInstance = ->
  if keyMapper == null
    keyMapper = new KeyMapper()
  return keyMapper

module.exports =
  getInstance: getInstance
