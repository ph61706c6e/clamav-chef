# -*- encoding: utf-8 -*-

require 'spec_helper'

describe 'clamav::services' do
  let(:platform) { { platform: nil, version: nil } }
  let(:services) { { clamd: nil, freshclam: nil } }
  let(:pids) do
    {
      clamd: '/var/run/clamav/clamd.pid',
      freshclam: '/var/run/clamav/freshclam.pid'
    }
  end
  let(:attributes) { {} }
  let(:runner) do
    ChefSpec::Runner.new(platform) do |node|
      attributes.each { |k, v| node.set[k] = v }
    end
  end
  let(:chef_run) { runner.converge(described_recipe) }

  shared_examples_for 'with anything' do
    it 'creates the PID file directories' do
      pids.each do |name, path|
        expect(chef_run).to create_directory(File.dirname(path)).with(
          user: 'clamav',
          group: 'clamav',
          recursive: true
        )
      end
    end
  end

  shared_examples_for 'with the freshclam service disabled' do
    it 'disables the service' do
      expect(chef_run).to disable_service(services[:freshclam])
      expect(chef_run).to stop_service(services[:freshclam])
    end
  end

  shared_examples_for 'with the freshclam service enabled' do
    it 'enables the service' do
      expect(chef_run).to enable_service(services[:freshclam])
      expect(chef_run).to start_service(services[:freshclam])
    end
  end

  shared_examples_for 'with the clamd service disabled' do
    it 'stops and disables the service' do
      expect(chef_run).to disable_service(services[:clamd])
      expect(chef_run).to stop_service(services[:clamd])
    end
  end

  shared_examples_for 'with the clamd service enabled' do
    it 'enables and starts the service' do
      expect(chef_run).to enable_service(services[:clamd])
      expect(chef_run).to start_service(services[:clamd])
    end
  end

  {
    Ubuntu: {
      platform: 'ubuntu',
      version: '12.04',
      clamd_service: 'clamav-daemon',
      freshclam_service: 'clamav-freshclam'
    },
    CentOS: {
      platform: 'centos',
      version: '6.4',
      clamd_service: 'clamd',
      freshclam_service: 'freshclam'
    }
  }.each do |k, v|
    context "a #{k} node" do
      let(:platform) { { platform: v[:platform], version: v[:version] } }
      let(:services) do
        { clamd: v[:clamd_service], freshclam: v[:freshclam_service] }
      end

      context 'with all default attributes' do
        it_behaves_like 'with anything'
        it_behaves_like 'with the clamd service disabled'
        it_behaves_like 'with the freshclam service disabled'
      end

      context 'with the clamd service enabled' do
        let(:attributes) { { clamav: { clamd: { enabled: true } } } }

        it_behaves_like 'with anything'
        it_behaves_like 'with the clamd service enabled'
        it_behaves_like 'with the freshclam service disabled'
      end

      context 'with the freshclam service enabled' do
        let(:attributes) { { clamav: { freshclam: { enabled: true } } } }

        it_behaves_like 'with anything'
        it_behaves_like 'with the clamd service disabled'
        it_behaves_like 'with the freshclam service enabled'
      end

      context 'with both services enabled' do
        let(:attributes) do
          {
            clamav: { clamd: { enabled: true }, freshclam: { enabled: true } }
          }
        end

        it_behaves_like 'with anything'
        it_behaves_like 'with the clamd service enabled'
        it_behaves_like 'with the freshclam service enabled'
      end

      context 'with overridden PID file paths' do
        let(:pids) { { clamd: '/tmp/r1/clam', freshclam: '/tmp/r2/fresh' } }
        let(:attributes) do
          {
            clamav: {
              clamd: { pid_file: pids[:clamd] },
              freshclam: { pid_file: pids[:freshclam] }
            }
          }
        end

        it_behaves_like 'with anything'
        it_behaves_like 'with the clamd service disabled'
        it_behaves_like 'with the freshclam service disabled'
      end
    end
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
