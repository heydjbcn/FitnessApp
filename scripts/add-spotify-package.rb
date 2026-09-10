# Enlaza el SDK oficial de Spotify (SPM, framework binario) al target de la app.
#   ruby scripts/add-spotify-package.rb
require 'xcodeproj'
ROOT = File.expand_path('..', __dir__)
proj = Xcodeproj::Project.open(File.join(ROOT, 'FitnessApp.xcodeproj'))
app = proj.targets.find { |t| t.name == 'FitnessApp' }

ref = proj.root_object.package_references.find { |r| r.repositoryURL.to_s.include?('spotify/ios-sdk') }
unless ref
  ref = proj.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  ref.repositoryURL = 'https://github.com/spotify/ios-sdk'
  ref.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '5.0.1' }
  proj.root_object.package_references << ref
end

unless app.package_product_dependencies.any? { |d| d.product_name == 'SpotifyiOS' }
  dep = proj.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package = ref
  dep.product_name = 'SpotifyiOS'
  app.package_product_dependencies << dep
  bf = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
  bf.product_ref = dep
  app.frameworks_build_phase.files << bf
end
proj.save
puts 'OK: SpotifyiOS enlazado'
