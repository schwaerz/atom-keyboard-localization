util = require('util')
KeymapLoader = require './keymap-loader'
KeyMapper = require './key-mapper'
ModifierStateHandler = require './modifier-state-handler'
KeymapGeneratorView = null
KeymapGeneratorUri = 'atom://keyboard-localization/keymap-manager'

createKeymapGeneratorView = (state) ->
  KeymapGeneratorView ?= require './views/keymap-generator-view'
  new KeymapGeneratorView(state)

atom.deserializers.add
  name: 'KeymapGeneratorView'
  deserialize: (state) -> createKeymapGeneratorView(state)

KeyboardLocalization =
  pkg: 'keyboard-localization'
  keystrokeForKeyboardEventCb: null
  keymapLoader: null
  keyMapper: null
  modifierStateHandler: null
  keymapGeneratorView: null

  config:
    useKeyboardLayout:
      type: 'string'
      default: 'de_DE'
      enum: [
        'da_DK'
        'de_DE-neo'
        'de_DE'
        'es_ES'
        'es_LA'
        'fr_BE'
        'fr_FR'
        'fr_CA'
        'hu_HU'
        'it_IT'
        'lv_LV'
        'nb_NO'
        'pl_PL'
        'pt_BR'
        'pt_PT'
        'ro_RO'
        'sl_SL'
        'sv_SE'
      ]
      description: 'Pick your locale'
    useKeyboardLayoutFromPath:
      type: 'string'
      default: ''
      description: 'Provide an absolute path to your keymap-json file'

  activate: (state) ->
    atom.workspace.addOpener (filePath) ->
      createKeymapGeneratorView(uri: KeymapGeneratorUri) if filePath is KeymapGeneratorUri

    atom.commands.add 'atom-workspace',
      'keyboard-localization:keymap-generator': -> atom.workspace.open(KeymapGeneratorUri)

    @keymapLoader = new KeymapLoader()
    @keymapLoader.loadKeymap()
    @keyMapper = KeyMapper.getInstance()
    @modifierStateHandler = new ModifierStateHandler()

    # listen for config changes and load keymap
    @changeUseKeyboardLayout = atom.config.onDidChange [@pkg, 'useKeyboardLayout'].join('.'), () =>
      @keymapLoader.loadKeymap()
      if @keymapLoader.isLoaded()
        @keyMapper.setKeymap(@keymapLoader.getKeymap())
    @changeUseKeyboardLayoutFromPath = atom.config.onDidChange [@pkg, 'useKeyboardLayoutFromPath'].join('.'), () =>
      @keymapLoader.loadKeymap()
      if @keymapLoader.isLoaded()
        @keyMapper.setKeymap(@keymapLoader.getKeymap())

    if @keymapLoader.isLoaded()
      @keyMapper.setKeymap(@keymapLoader.getKeymap())
      @keyMapper.setModifierStateHandler(@modifierStateHandler)

      # Hijack KeymapManager
      # @TODO: Evil hack. Find an better way ...
      @orginalKeydownEvent = atom.keymaps.keystrokeForKeyboardEvent
      atom.keymaps.keystrokeForKeyboardEvent = (event) =>
        @onKeyDown event

  deactivate: ->
    if @keymapLoader.isLoaded()
      atom.keymaps.keystrokeForKeyboardEvent = @orginalKeydownEvent
      @orginalKeydownEvent = null

    @changeUseKeyboardLayout.dispose()
    @changeUseKeyboardLayoutFromPath.dispose()

    @keymapGeneratorView?.destroy()

    @modifierStateHandler = null
    @keymapLoader = null
    @keyMapper = null
    @keymapGeneratorView = null

  onKeyDown: (event, cb) ->
    @modifierStateHandler.handleKeyEvent(event)
    @keyMapper.remap(event)
    return @orginalKeydownEvent(event)

module.exports = KeyboardLocalization
