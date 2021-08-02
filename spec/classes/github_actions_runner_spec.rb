require 'spec_helper'

describe 'github_actions_runner' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'org_name' => 'github_org',
          'instances' => {
            'first_runner' => {
              'labels' => ['test_label1', 'test_label2'],
              'repo_name' => 'test_repo',
            },
          },
        }
      end

      defaults = {
        'Linux' => {
          root_path: '/some_dir/actions-runner-2.272.0',
          archive: 'actions-runner-linux-x64-2.272.0.tar.gz',
          configurator: 'configure_install_runner.sh',
          ownership: 'root',
        },
        'windows' => {
          root_path: 'C:/some_dir/actions-runner-2.272.0',
          archive: 'actions-runner-win-x64-2.272.0.zip',
          configurator: 'configure_install_runner.ps1',
          ownership: 'Administrator',
        },
      }

      context 'is expected compile' do
        it do
          is_expected.to compile.with_all_deps
          is_expected.to contain_class('github_actions_runner')
        end
      end

      context 'is expected compile and raise error when required values are undefined' do
        let(:params) do
          super().merge('org_name' => :undef, 'enterprise_name' => :undef)
        end

        it do
          is_expected.to compile.and_raise_error(%r{Either 'org_name' or 'enterprise_name' is required to create runner instances})
        end
      end

      context 'is expected to create a github_actions_runner root directory' do
        it do
          is_expected.to contain_file(defaults[os_facts[:kernel]][:root_path]).with(
            'ensure' => 'directory',
            'owner'  => defaults[os_facts[:kernel]][:ownership],
            'group'  => defaults[os_facts[:kernel]][:ownership],
            'mode'   => '0644',
          )
        end
      end

      context 'is expected to create a github_actions_runner a new root directory' do
        let(:params) do
          super().merge('base_dir_name' => '/tmp/actions-runner')
        end

        it do
          is_expected.to contain_file('/tmp/actions-runner-2.272.0').with(
            'ensure' => 'directory',
            'owner'  => defaults[os_facts[:kernel]][:ownership],
            'group'  => defaults[os_facts[:kernel]][:ownership],
            'mode'   => '0644',
          )
        end
      end

      context 'is expected to create a github_actions_runner root directory with test user' do
        let(:params) do
          super().merge('user'  => 'test_user',
                        'group' => 'test_group')
        end

        it do
          is_expected.to contain_file(defaults[os_facts[:kernel]][:root_path]).with(
            'ensure' => 'directory',
            'owner'  => 'test_user',
            'group'  => 'test_group',
            'mode'   => '0644',
          )
        end
      end

      context 'is expected to create a github_actions_runner instance directory' do
        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner").with(
            'ensure' => 'directory',
            'owner'  => defaults[os_facts[:kernel]][:ownership],
            'group'  => defaults[os_facts[:kernel]][:ownership],
            'mode'   => '0644',
          )
        end
      end

      context 'is expected to create a github_actions_runner instance directory with test user' do
        let(:params) do
          super().merge('user'  => 'test_user',
                        'group' => 'test_group')
        end

        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner").with(
            'ensure' => 'directory',
            'owner'  => 'test_user',
            'group'  => 'test_group',
            'mode'   => '0644',
          )
        end
      end

      context 'is expected to contain archive' do
        it do
          is_expected.to contain_archive("first_runner-#{defaults[os_facts[:kernel]][:archive]}").with(
            'ensure' => 'present',
            'user'   => defaults[os_facts[:kernel]][:ownership],
            'group'  => defaults[os_facts[:kernel]][:ownership],
          )
        end
      end

      context 'is expected to contain rar archive with test package and test url' do
        let(:params) do
          super().merge('package_name'      => 'test_package',
                        'package_ensure'    => '9.9.9',
                        'repository_url'    => 'https://test_url',
                        'package_extension' => 'rar')
        end

        it do
          is_expected.to contain_archive('first_runner-test_package-9.9.9.rar').with(
            'ensure' => 'present',
            'user'   => defaults[os_facts[:kernel]][:ownership],
            'group'  => defaults[os_facts[:kernel]][:ownership],
            'source' => 'https://test_url/v9.9.9/test_package-9.9.9.rar',
          )
        end
      end

      context 'is expected to contain a run exec' do
        it do
          if os_facts[:kernel] == 'windows'
            is_expected.to contain_exec('first_runner-run_configure_install_runner').with(
              'command' => "#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}",
              'provider' => 'powershell',
            )
          else
            is_expected.to contain_exec('first_runner-run_configure_install_runner').with(
              'user'    => defaults[os_facts[:kernel]][:ownership],
              'command' => "#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}",
            )
          end
        end
      end

      context 'is expected to create a github_actions_runner installation script' do
        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with(
            'ensure' => 'present',
            'owner'  => defaults[os_facts[:kernel]][:ownership],
            'group'  => defaults[os_facts[:kernel]][:ownership],
            'mode'   => '0755',
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with test version' do
        let(:params) do
          super().merge('base_dir_name' => '/tmp/actions-runner',
                        'package_ensure' => '9.9.9')
        end

        it do
          is_expected.to contain_file("/tmp/actions-runner-9.9.9/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with(
            'ensure' => 'present',
            'owner'  => defaults[os_facts[:kernel]][:ownership],
            'group'  => defaults[os_facts[:kernel]][:ownership],
            'mode'   => '0755',
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with config in content' do
        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{/some_dir/actions-runner-2.272.0/first_runner/config},
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with github org in content' do
        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{https://github.com/github_org/test_repo},
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with test_org in content ignoring enterprise_name' do
        let(:params) do
          super().merge('org_name' => 'test_org', 'enterprise_name' => 'test_enterprise')
        end

        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{https://github.com/test_org/test_repo},
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with test_org in content' do
        let(:params) do
          super().merge('org_name' => 'test_org')
        end

        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{https://github.com/test_org/test_repo},
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with test_enterprise in content' do
        let(:params) do
          super().merge('org_name'        => :undef,
                        'enterprise_name' => 'test_enterprise')
        end

        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{https://github.com/enterprises/test_enterprise},
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with labels in content' do
        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{test_label1,test_label2},
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with PAT in content' do
        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{token PAT},
          )
        end
      end

      context 'is expected to create a github_actions_runner installation script with test_PAT in content' do
        let(:params) do
          super().merge('personal_access_token' => 'test_PAT')
        end

        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(
            %r{token test_PAT},
          )
        end
      end

      if os_facts[:kernel] == 'Linux'
        context 'is expected to contain an ownership exec' do
          it do
            if os_facts[:kernel] == 'windows'
              is_expected.to contain_exec('first_runner-run_configure_install_runner').with(
                'command' => 'Icacls -R /some_dir/actions-runner-2.272.0/first_runner /T /Q /grant Administrator:F',
                'provider' => powershell,
              )
            else
              is_expected.to contain_exec('first_runner-ownership').with(
                'user'    => defaults[os_facts[:kernel]][:ownership],
                'command' => '/bin/chown -R root:root /some_dir/actions-runner-2.272.0/first_runner',
              )
            end
          end
        end

        context 'is expected to create a github_actions_runner with service active and enabled' do
          let(:params) do
            super().merge(
              'http_proxy' => 'http://proxy.local',
              'https_proxy' => 'http://proxy.local',
              'no_proxy' => 'example.com',
              'instances' => {
                'first_runner' => {
                  'labels' => ['test_label1'],
                  'repo_name' => 'test_repo',
                },
              },
            )
          end

          it do
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with(
              'ensure' => 'present',
              'enable' => true,
              'active' => true,
            )
          end
        end

        context 'is expected to remove github_actions_runner unit_file and other resources' do
          let(:params) do
            super().merge(
              'http_proxy' => 'http://proxy.local',
              'https_proxy' => 'http://proxy.local',
              'no_proxy' => 'example.com',
              'instances' => {
                'first_runner' => {
                  'ensure' => 'absent',
                  'labels' => ['test_label1'],
                  'repo_name' => 'test_repo',
                },
              },
            )
          end

          it do
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with(
              'ensure' => 'absent',
              'enable' => false,
              'active' => false,
            )
            is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner").with(
              'ensure' => 'absent',
            )
            is_expected.to contain_archive("first_runner-#{defaults[os_facts[:kernel]][:archive]}").with(
              'ensure' => 'absent',
            )
            is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with(
              'ensure' => 'absent',
            )
          end
        end

        context 'is expected to create a github_actions_runner installation with proxy settings in systemd globally in init.pp' do
          let(:params) do
            super().merge(
              'http_proxy' => 'http://proxy.local',
              'https_proxy' => 'http://proxy.local',
              'no_proxy' => 'example.com',
              'instances' => {
                'first_runner' => {
                  'labels' => ['test_label1'],
                  'repo_name' => 'test_repo',
                },
              },
            )
          end

          it do
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="http_proxy=http://proxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="https_proxy=http://proxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="no_proxy=example.com"})
          end
        end

        context 'is expected to create a github_actions_runner installation with proxy settings in systemd globally in init.pp overwriting in a instance' do
          let(:params) do
            super().merge(
              'http_proxy' => 'http://proxy.local',
              'https_proxy' => 'http://proxy.local',
              'no_proxy' => 'example.com',
              'instances' => {
                'first_runner' => {
                  'labels' => ['test_label1'],
                  'repo_name' => 'test_repo',
                  'http_proxy' => 'http://newproxy.local',
                },
              },
            )
          end

          it do
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="http_proxy=http://newproxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="https_proxy=http://proxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="no_proxy=example.com"})
          end
        end

        context 'is expected to create a github_actions_runner installation with proxy settings in systemd' do
          let(:params) do
            super().merge(
              'instances' => {
                'first_runner' => {
                  'labels' => ['test_label1'],
                  'repo_name' => 'test_repo',
                  'http_proxy' => 'http://proxy.local',
                  'https_proxy' => 'http://proxy.local',
                  'no_proxy' => 'example.com',
                },
              },
            )
          end

          it do
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="http_proxy=http://proxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="https_proxy=http://proxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').with_content(%r{Environment="no_proxy=example.com"})
          end
        end

        context 'is expected to create a github_actions_runner installation without proxy settings in systemd' do
          let(:params) do
            super().merge(
              'instances' => {
                'first_runner' => {
                  'labels' => ['test_label1'],
                  'repo_name' => 'test_repo',
                },
              },
            )
          end

          it do
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').without_content(%r{Environment="http_proxy=http://proxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').without_content(%r{Environment="https_proxy=http://proxy.local"})
            is_expected.to contain_systemd__unit_file('github-actions-runner.first_runner.service').without_content(%r{Environment="no_proxy=example.com"})
          end
        end
      end

      context 'is expected to create a github_actions_runner installation with another URLs for domain and API' do
        let(:params) do
          super().merge(
            'github_domain' => 'https://git.example.com',
            'github_api' => 'https://git.example.com/api/v3',
            'instances' => {
              'first_runner' => {
                'labels' => ['test_label1'],
                'repo_name' => 'test_repo',
              },
            },
          )
        end

        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(%r{--url https://git.example.com})
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(%r{https://git.example.com/api/v3.*})
        end
      end

      context 'is expected to create a github_actions_runner installation with another URLs for domain and API per instance' do
        let(:params) do
          super().merge(
            'instances' => {
              'first_runner' => {
                'labels' => ['test_label1'],
                'repo_name' => 'test_repo',
              },
              'second_runner' => {
                'labels' => ['test_label1'],
                'repo_name' => 'test_repo',
                'github_domain' => 'https://git.example.foo',
                'github_api' => 'https://git.example.foo/api/v2',
              },
            },
          )
        end

        it do
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(%r{--url https://github.com})
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/first_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(%r{https://api.github.com/.*})
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/second_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(%r{--url https://git.example.foo})
          is_expected.to contain_file("#{defaults[os_facts[:kernel]][:root_path]}/second_runner/#{defaults[os_facts[:kernel]][:configurator]}").with_content(%r{https://git.example.foo/api/v2/.*})
        end
      end
    end
  end
end
