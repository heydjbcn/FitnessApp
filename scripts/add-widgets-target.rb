# Añade el target ChamaFitWidgets (Widget Extension: Live Activity del descanso
# y widget de pantalla de inicio), lo embebe en la app, comparte Shared/ entre
# app y extensión, y deja el proyecto solo para iPhone en vertical.
#
#   ruby scripts/add-widgets-target.rb
#
# Idempotente: si el target ya existe, solo reaplica los ajustes.

require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
proj = Xcodeproj::Project.open(File.join(ROOT, 'FitnessApp.xcodeproj'))

app   = proj.targets.find { |t| t.name == 'FitnessApp' } or abort 'no encuentro el target FitnessApp'
watch = proj.targets.find { |t| t.name == 'AppFit Watch' } or abort 'no encuentro el target AppFit Watch'
tests = proj.targets.select { |t| t.name.end_with?('Tests') }
TEAM = '47BY9SGLT7'

# ---------------------------------------------------------------- Shared/
shared_group = proj.main_group['Shared'] || proj.main_group.new_group('Shared', 'Shared')
shared_refs = Dir[File.join(ROOT, 'Shared', '*.swift')].sort.map do |path|
  name = File.basename(path)
  shared_group.files.find { |f| f.path == name } || shared_group.new_file(name)
end
# La app compila su carpeta sincronizada; Shared/ está fuera, así que se añade a mano.
shared_refs.each do |ref|
  app.add_file_references([ref]) unless app.source_build_phase.files_references.include?(ref)
end

# ---------------------------------------------------------------- Widget target
widget = proj.targets.find { |t| t.name == 'ChamaFitWidgets' }
unless widget
  widget = proj.new_target(:app_extension, 'ChamaFitWidgets', :ios, '26.0', proj.products_group, :swift)
  group = proj.main_group.new_group('ChamaFitWidgets', 'ChamaFitWidgets')
  swift = Dir[File.join(ROOT, 'ChamaFitWidgets', '*.swift')].sort.map { |p| group.new_file(File.basename(p)) }
  group.new_file('Info.plist')
  group.new_file('ChamaFitWidgets.entitlements')
  widget.add_file_references(swift)
  widget.add_file_references(shared_refs)

  embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.dst_subfolder_spec = '13' # PlugIns
  embed.dst_path = ''
  bf = embed.add_file_reference(widget.product_reference)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  app.add_dependency(widget)
end

widget.build_configurations.each do |c|
  c.build_settings.merge!(
    'CODE_SIGN_STYLE' => 'Automatic',
    'DEVELOPMENT_TEAM' => TEAM,
    'CODE_SIGN_ENTITLEMENTS' => 'ChamaFitWidgets/ChamaFitWidgets.entitlements',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'INFOPLIST_FILE' => 'ChamaFitWidgets/Info.plist',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'ChamaFit',
    'INFOPLIST_KEY_NSHumanReadableCopyright' => '',
    'IPHONEOS_DEPLOYMENT_TARGET' => '26.0',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
    'MARKETING_VERSION' => '2.0',
    'CURRENT_PROJECT_VERSION' => '1',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'Mauri.FitnessApp.ChamaFitWidgets',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SDKROOT' => 'iphoneos',
    'SKIP_INSTALL' => 'YES',
    'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
    'SWIFT_VERSION' => '5.0',
    'SWIFT_APPROACHABLE_CONCURRENCY' => 'YES',
    'SWIFT_DEFAULT_ACTOR_ISOLATION' => 'MainActor',
    'SWIFT_EMIT_LOC_STRINGS' => 'YES',
    'TARGETED_DEVICE_FAMILY' => '1',
  )
end

# ---------------------------------------------------------------- App
app.build_configurations.each do |c|
  s = c.build_settings
  %w[ENABLE_APP_SANDBOX ENABLE_HARDENED_RUNTIME ENABLE_USER_SELECTED_FILES MACOSX_DEPLOYMENT_TARGET
     XROS_DEPLOYMENT_TARGET LD_RUNPATH_SEARCH_PATHS[sdk=macosx*] INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad].each { |k| s.delete(k) }
  s.merge!(
    'CODE_SIGN_ENTITLEMENTS' => 'FitnessApp/FitnessApp.entitlements',
    'INFOPLIST_FILE' => 'FitnessApp/Info.plist',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'ChamaFit',
    'INFOPLIST_KEY_NSSupportsLiveActivities' => 'YES',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone' => 'UIInterfaceOrientationPortrait',
    'MARKETING_VERSION' => '2.0',
    'CURRENT_PROJECT_VERSION' => '1',
    'SDKROOT' => 'iphoneos',
    'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
    'TARGETED_DEVICE_FAMILY' => '1'
  )
end

# ---------------------------------------------------------------- Watch
watch_group = proj.main_group['WatchApp'] || proj.main_group.new_group('WatchApp', 'WatchApp')
Dir[File.join(ROOT, 'WatchApp', '*.swift')].sort.each do |path|
  name = File.basename(path)
  ref = watch_group.files.find { |f| f.path == name } || watch_group.new_file(name)
  watch.add_file_references([ref]) unless watch.source_build_phase.files_references.include?(ref)
end
watch_group.files.find { |f| f.path == 'Watch.entitlements' } || watch_group.new_file('Watch.entitlements')
watch.build_configurations.each do |c|
  c.build_settings.merge!(
    'CODE_SIGN_ENTITLEMENTS' => 'WatchApp/Watch.entitlements',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'ChamaFit',
    'INFOPLIST_KEY_NSHealthShareUsageDescription' => 'ChamaFit lee tu ritmo cardíaco y las calorías durante el entrenamiento para mostrarlos en el reloj.',
    'INFOPLIST_KEY_NSHealthUpdateUsageDescription' => 'ChamaFit guarda cada sesión como entrenamiento de fuerza en Salud para que cuente en tus anillos.',
    'MARKETING_VERSION' => '2.0',
    'WATCHOS_DEPLOYMENT_TARGET' => '11.0'
  )
end

# ---------------------------------------------------------------- Tests
tests.each do |t|
  t.build_configurations.each do |c|
    s = c.build_settings
    %w[MACOSX_DEPLOYMENT_TARGET XROS_DEPLOYMENT_TARGET].each { |k| s.delete(k) }
    s.merge!('SDKROOT' => 'iphoneos', 'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator', 'TARGETED_DEVICE_FAMILY' => '1')
  end
end

proj.save
puts "OK: targets = #{proj.targets.map(&:name).join(', ')}"
