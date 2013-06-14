require 'spec_helper'

module Capistrano
  class Configuration
    describe Servers do
      let(:servers) { Servers.new }

      describe 'adding a role' do

        it 'adds two new server instances' do
          expect{servers.add_role(:app, %w{1 2})}.
            to change{servers.count}.from(0).to(2)
        end

        it 'handles de-duplification within roles' do
          servers.add_role(:app, %w{1})
          servers.add_role(:app, %w{1})
          expect(servers.count).to eq 1
        end

        it 'accepts instances of server objects' do
          servers.add_role(:app, [Capistrano::Configuration::Server.new('example.net'), 'example.com'])
          expect(servers.roles_for([:app]).length).to eq 2
        end

        it 'accepts non-enumerable types' do
          servers.add_role(:app, '1')
          expect(servers.roles_for([:app]).count).to eq 1
        end

      end

      describe 'adding a role to an existing server' do
        before do
          servers.add_role(:web, %w{1 2})
          servers.add_role(:app, %w{1 2})
        end

        it 'adds new roles to existing servers' do
          expect(servers.count).to eq 2
        end

      end

      describe 'collecting server roles' do
        let(:app) { Set.new([:app]) }
        let(:web_app) { Set.new([:web, :app]) }
        let(:web) { Set.new([:web]) }

        before do
          servers.add_role(:app, %w{1 2 3})
          servers.add_role(:web, %w{2 3 4})
        end

        it 'returns an array of the roles' do
          expect(servers.roles_for([:app]).collect(&:roles)).to eq [app, web_app, web_app]
          expect(servers.roles_for([:web]).collect(&:roles)).to eq [web_app, web_app, web]
        end
      end

      describe 'finding the primary server' do
        it 'takes the first server if none have the primary property' do
          servers.add_role(:app, %w{1 2})
          servers.fetch_primary(:app).hostname.should == '1'
        end

        it 'takes the first server with the primary have the primary flag' do
          servers.add_role(:app, %w{1 2})
          servers.add_host('2', primary: true)
          servers.fetch_primary(:app).hostname.should == '2'
        end
      end

      describe 'fetching servers' do
        before do
          servers.add_role(:app, %w{1 2})
          servers.add_role(:web, %w{2 3})
        end

        it 'returns the correct app servers' do
          expect(servers.roles_for([:app]).map(&:hostname)).to eq %w{1 2}
        end

        it 'returns the correct web servers' do
          expect(servers.roles_for([:web]).map(&:hostname)).to eq %w{2 3}
        end

        it 'returns the correct app and web servers' do
          expect(servers.roles_for([:app, :web]).map(&:hostname)).to eq %w{1 2 3}
        end

        it 'returns all servers' do
          expect(servers.roles_for([:all]).map(&:hostname)).to eq %w{1 2 3}
        end
      end

      describe 'adding a server' do

        before do
          servers.add_host('1', roles: [:app, 'web'], test: :value)
        end

        it 'can create a server with properties' do
          expect(servers.roles_for([:app]).first.hostname).to eq '1'
          expect(servers.roles_for([:web]).first.hostname).to eq '1'
          expect(servers.roles_for([:all]).first.properties.test).to eq :value
        end

      end

      describe '#roles' do

        before do
          servers.add_host('1', roles: :app, active: true)
          servers.add_host('2', roles: :app)
        end

        it 'raises if the filter would remove all matching hosts' do
          I18n.expects(:t)
          expect { servers.roles_for([:app, select: :inactive]) }.to raise_error
        end

        it 'can filter hosts by properties on the host object using symbol as shorthand' do
          expect(servers.roles_for([:app, filter: :active]).length).to eq 1
        end

        it 'can select hosts by properties on the host object using symbol as shorthand' do
          expect(servers.roles_for([:app, select: :active]).length).to eq 1
        end

        it 'can filter hosts by properties on the host using a regular proc' do
          expect(servers.roles_for([:app, filter: lambda { |h| h.properties.active }]).length).to eq 1
        end

        it 'can select hosts by properties on the host using a regular proc' do
          expect(servers.roles_for([:app, select: lambda { |h| h.properties.active }]).length).to eq 1
        end

        it 'raises if the regular proc filter would remove all matching hosts' do
          I18n.expects(:t)
          expect { servers.roles_for([:app, select: lambda { |h| h.properties.inactive }])}.to raise_error
        end

      end
    end
  end
end