module ChefSpec
  module MiniTestHelpers

    def run_examples_successfully
      run_simple 'ruby cookbooks/example/spec/default_spec.rb'
      assert_success(true)
      assert_partial_output ', 0 failures', all_output
    end

    def run_examples_unsuccessfully(failure_message)
      run_simple 'ruby cookbooks/example/spec/default_spec.rb', false
      assert_success(false)
      assert_partial_output failure_message, all_output
    end

    def spec_expects_directory
      generate_spec %q{
        it "creates the directory" do
          directory("foo").must_exist
        end
      }
    end

    def spec_expects_directory_to_be_deleted
      generate_spec %q{
        it "deletes the directory" do
          directory("foo").wont_exist
        end
      }
    end

    def spec_expects_directory_with_ownership
      generate_spec %q{
        it "sets directory ownership" do
          directory('foo').must_exist.with(:owner, 'user').and(:group, 'group')
        end
      }
    end

    def spec_expects_file(resource_type, path = 'hello-world.txt')
      generate_spec %Q{
        it "creates #{path}" do
          file("#{path}").must_exist
        end
      }
    end

    def spec_expects_file_to_be_deleted
      generate_spec %q{
        it "deletes hello-world.txt" do
          file("hello-world.txt").wont_exist
        end
      }
    end

    def spec_expects_file_with_content
      generate_spec %q{
        it "creates hello-world.txt with content" do
          file("hello-world.txt").must_include 'hello world'
        end
      }
    end

    def spec_expects_file_with_rendered_content
      generate_spec %q{
        it "should create a file with the node platform" do
          expected_content = <<-EOF.gsub /^\s*/, ''
            # Config file generated by Chef
            platform: chefspec
          EOF
          file('/etc/config_file').must_include expected_content
        end
      }
    end

    def spec_expects_file_with_ownership(resource_type)
      generate_spec %q{
        it "sets file ownership" do
          file("hello-world.txt").must_exist.with(:owner, 'user').and(:group, 'group')
        end
      }
    end

    def spec_expects_gem_action(action)
      assertion = case action
        when :remove, :purge then 'wont_be_installed'
        else 'must_be_installed'
      end
      generate_spec %Q{
        it "#{action}s the gem" do
          gem_package("gem_package_does_not_exist").#{assertion}
        end
      }
    end

    def spec_expects_gem_at_specific_version
      generate_spec %q{
        it "installs the gem at a specific version" do
          gem_package("gem_package_does_not_exist").must_be_installed.with(:version, '1.2.3')
        end
      }
    end

    def spec_expects_package_action(action)
      assertion = case action
        when :remove, :purge then 'wont_be_installed'
        when :upgrade then raise NotImplementedError, 'The :upgrade action is not supported'
        else 'must_be_installed'
      end

      generate_spec %Q{
        it "#{action}s package_does_not_exist" do
          package('package_does_not_exist').#{assertion}
        end
      }
    end

    def spec_expects_package_at_specific_version
      generate_spec %q{
        it "installs package_does_not_exist" do
          package('package_does_not_exist').must_be_installed.with(:version, '1.2.3')
        end
      }
    end

    def spec_expects_service_action(action)
      assertion = case action
        when :stop then 'wont_be_running'
        else 'must_be_running'
      end
      generate_spec %Q{
        it "#{action.to_s} the food service" do
          service('food').#{assertion}
        end
      }
    end

    def spec_expects_service_to_be_started_and_enabled
      generate_spec %q{
        it "ensures the food service is started and enabled" do
          service('food').must_be_running
          service('food').must_be_enabled
        end
      }
    end

    private

    def generate_spec(example)
      write_file 'cookbooks/example/spec/default_spec.rb', %Q{
        require "chefspec"
        require "minitest/autorun"
        require "minitest/spec"
        require "minitest-chef-handler"

        describe_recipe "example::default"  do

          include MiniTest::Chef::Assertions
          include MiniTest::Chef::Context
          include MiniTest::Chef::Resources
          include ChefSpec::MiniTest

          #{example}
        end
      }
    end

    def spec_expects_user_action(action)
      write_file 'cookbooks/example/spec/default_spec.rb', %Q{
        require "chefspec"

        describe "example::default" do
          let(:chef_run) { ChefSpec::ChefRunner.new.converge 'example::default' }
          it "should #{action.to_s} the user foo" do
            chef_run.should #{action.to_s}_user 'foo'
          end
        end
      }
    end

  end
end
