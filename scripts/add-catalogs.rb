# Añade los catálogos de textos (Localizable.xcstrings) a los targets que no
# están en una carpeta sincronizada: widgets, reloj y widgets del reloj.
#
#   ruby scripts/add-catalogs.rb      (idempotente)

require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
proj = Xcodeproj::Project.open(File.join(ROOT, 'FitnessApp.xcodeproj'))

{ 'ChamaFitWidgets' => 'ChamaFitWidgets', 'AppFit Watch' => 'WatchApp', 'ChamaFitWatchWidgets' => 'ChamaFitWatchWidgets' }.each do |tname, dir|
  target = proj.targets.find { |t| t.name == tname } or next
  group = proj.main_group[dir] or next
  %w[Localizable.xcstrings InfoPlist.xcstrings].each do |file|
    next unless File.exist?(File.join(ROOT, dir, file))
    ref = group.files.find { |f| f.path == file } || group.new_file(file)
    ref.last_known_file_type = 'text.json.xcstrings'
    unless target.resources_build_phase.files_references.include?(ref)
      target.resources_build_phase.add_file_reference(ref)
      puts "#{tname}: + #{file}"
    end
  end
end

# Idiomas del proyecto.
proj.root_object.known_regions = (proj.root_object.known_regions | %w[es en ca Base]).uniq
proj.save
puts 'ok'
