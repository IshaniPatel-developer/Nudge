require 'xcodeproj'

PROJECT_PATH = '/Users/ishani/Documents/Ishani/Nudge/Nudge.xcodeproj'
FONT_FILES   = %w[Inter-Regular.ttf Inter-Medium.ttf Inter-SemiBold.ttf Inter-Bold.ttf]
FONTS_RELATIVE = 'Nudge/Resources/Fonts'  # relative to project root

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == 'Nudge' }
abort("Target 'Nudge' not found") unless target

# ── 1. Find or create a traditional PBXGroup for Fonts under main_group ──────
# We work under the top-level main_group with a flat Fonts subgroup.
main_group = project.main_group

fonts_group = main_group.children.find { |c| c.respond_to?(:name) && c.name == 'InterFonts' }
unless fonts_group
  fonts_group = main_group.new_group('InterFonts', FONTS_RELATIVE, '<group>')
  puts "  ✅ Created InterFonts group"
end

# ── 2. Add each TTF as a file reference ──────────────────────────────────────
copy_phase = target.resources_build_phase

FONT_FILES.each do |filename|
  full_path = File.join(File.dirname(PROJECT_PATH), FONTS_RELATIVE, filename)
  next unless File.exist?(full_path)

  # Skip if already referenced by path
  already = fonts_group.children.any? { |c| c.respond_to?(:path) && c.path == filename }
  next if already

  ref = fonts_group.new_file(filename)
  ref.last_known_file_type = 'org.khronos.opentype-font'
  ref.source_tree = '<group>'

  # Add to Copy Bundle Resources unless already there
  already_in_phase = copy_phase.files_references.any? { |f| f.path == filename rescue false }
  copy_phase.add_file_reference(ref) unless already_in_phase

  puts "  ✅ Added #{filename}"
end

# ── 3. Register UIAppFonts in build settings ──────────────────────────────────
font_value = FONT_FILES.join(' ')

[project.build_configurations, target.build_configurations].each do |configs|
  configs.each do |config|
    existing = config.build_settings['INFOPLIST_KEY_UIAppFonts'].to_s
    unless existing.include?('Inter-Regular.ttf')
      config.build_settings['INFOPLIST_KEY_UIAppFonts'] = font_value
      puts "  ✅ UIAppFonts set in [#{config.name}]"
    end
  end
end

project.save
puts "\n🎉 Done — Inter fonts registered in Nudge.xcodeproj."
