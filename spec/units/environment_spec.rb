require 'spec_helper'
require 'gitsh/environment'

describe Gitsh::Environment do
  describe '#[]=' do
    it 'sets a gitsh environment variable' do
      repository = stub('GitRepository', config: nil)
      factory = stub(new: repository)
      env = described_class.new(repository_factory: factory)

      expect(env[:foo]).to be_nil
      expect(env['foo']).to be_nil
      env['foo'] = 'bar'
      expect(env[:foo]).to eq 'bar'
      expect(env['foo']).to eq 'bar'
    end
  end

  describe '#[]' do
    it 'reads a gitsh environment variable' do
      env = described_class.new
      env[:foo] = 'bar'

      expect(env[:foo]).to eq 'bar'
      expect(env['foo']).to eq 'bar'
    end

    it 'reads a git config variables' do
      repository = stub('GitRepository')
      repository.stubs(:config).with('user.name').returns('Joe Bloggs')
      factory = stub(new: repository)
      env = described_class.new(repository_factory: factory)

      expect(env['user.name']).to eq 'Joe Bloggs'
      expect(env[:'user.name']).to eq 'Joe Bloggs'
    end

    it 'prefers gitsh environment variables to git config variables' do
      repository = stub
      repository.stubs(:config).with('user.name').returns('Joe Bloggs')
      factory = stub(new: repository)
      env = described_class.new(repository_factory: factory)
      env[:'user.name'] = 'Jane Doe'

      expect(env['user.name']).to eq 'Jane Doe'
      expect(env[:'user.name']).to eq 'Jane Doe'
    end
  end

  describe '#fetch' do
    it 'reads a gitsh environment variable' do
      env = described_class.new
      env[:foo] = 'bar'

      expect(env.fetch(:foo, 'default')).to eq 'bar'
      expect(env.fetch('foo', 'default')).to eq 'bar'
    end

    it 'reads a git config variable when there is no environment variable' do
      repository = stub('GitRepository')
      repository.stubs(:config).with('user.name', 'default').returns('John Smith')
      env = described_class.new(repository_factory: stub(new: repository))

      expect(env.fetch('user.name', 'default')).to eq 'John Smith'
    end
  end

  describe '#config_variables' do
    it 'returns variables that have a dot in the name' do
      env = described_class.new
      env['example'] = '1'
      env['user.name'] = 'Joe Bloggs'
      env['user.email'] = 'joe@example.com'

      expect(env.config_variables).to eq(
        :'user.name' => 'Joe Bloggs',
        :'user.email' => 'joe@example.com'
      )
    end
  end

  describe '#output_stream' do
    it 'returns $stdout by default' do
      env = described_class.new

      expect(env.output_stream).to eq $stdout
    end

    it 'can be overridden in the constructor' do
      stream = stub
      env = described_class.new(output_stream: stream)

      expect(env.output_stream).to eq stream
    end
  end

  describe '#git_command' do
    it 'defaults to "/usr/bin/env git"' do
      env = described_class.new

      expect(env.git_command).to eq '/usr/bin/env git'
    end

    it 'can be overridden' do
      env = described_class.new
      env.git_command = '/path/to/git'

      expect(env.git_command).to eq '/path/to/git'
    end
  end

  describe '#print' do
    it 'prints to the output stream' do
      output = StringIO.new
      env = described_class.new(output_stream: output)

      env.print 'Hello world'

      expect(output.string).to eq 'Hello world'
    end
  end

  describe '#puts' do
    it 'prints to the output stream' do
      output = StringIO.new
      env = described_class.new(output_stream: output)

      env.puts 'Hello world'

      expect(output.string).to eq "Hello world\n"
    end
  end

  describe '#puts_error' do
    it 'prints to the error stream' do
      error = StringIO.new
      env = described_class.new(error_stream: error)

      env.puts_error 'Oh no!'

      expect(error.string).to eq "Oh no!\n"
    end
  end

  context 'delegated methods' do
    let(:repo) { stub }
    let(:repo_factory) { stub(new: repo) }
    let(:env) { described_class.new(repository_factory: repo_factory) }

    describe '#repo_current_head' do
      it 'is delegated to the GitRepository' do
        current_head = stub
        repo.stubs(:current_head).returns(current_head)

        expect(env.repo_current_head).to eq current_head
      end
    end

    describe '#repo_initialized?' do
      it 'is delegated to the GitRepository' do
        initialized = stub
        repo.stubs(:initialized?).returns(initialized)

        expect(env.repo_initialized?).to eq initialized
      end
    end

    describe '#repo_has_modified_files?' do
      it 'is delegated to the GitRepository' do
        has_modified_files = stub
        repo.stubs(:has_modified_files?).returns(has_modified_files)

        expect(env.repo_has_modified_files?).to eq has_modified_files
      end
    end

    describe '#repo_has_untracked_files?' do
      it 'is delegated to the GitRepository' do
        has_untracked_files = stub
        repo.stubs(:has_untracked_files?).returns(has_untracked_files)

        expect(env.repo_has_untracked_files?).to eq has_untracked_files
      end
    end
  end
end
