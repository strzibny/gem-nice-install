require 'rubygems/user_interaction'

module Gem
  pre_install do |gem_installer|
    unless gem_installer.spec.extensions.empty?
      gem_installer.extend Gem::Installer::Nice
    end
  end


  class Installer
    module Nice
      require 'rubygems/nice_install/distro_guesser'

      include Gem::UserInteraction

      def build_extensions
        super
      rescue ExtensionBuildError => e
        # Install platform dependencies and try the build again.
        if install_platform_dependencies
          super
        else
          raise
        end
      end

      def install_platform_dependencies
        if ext_installer = DistroGuesser.distro_ext_installer
          missing_deps = ext_installer.gem_ext_dependencies_for(spec.name).delete_if do |t|
            ext_installer.ext_dependency_present?(t)
          end

          unless missing_deps.empty?
            say "Installing native dependencies for Gem '#{spec.name}': #{missing_deps.join ' '}"
            unless ext_installer.install_ext_dependencies_for(spec.name, missing_deps)
              raise Gem::InstallError, "Failed to install native dependencies for '#{spec.name}'."
            end
          end
          return true
        end
      end
    end
  end
end
