# Copyright 2016-2021 Shine Solutions Group
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'retries'
require 'rexml/document'

module RubyAem
  module Resources
    # Package class contains API calls related to managing an AEM package.
    class Package
      include REXML
      # Initialise a package.
      # Package name and version will then be used to construct the package file in the filesystem.
      # E.g. package name 'somepackage' with version '1.2.3' will translate to somepackage-1.2.3.zip in the filesystem.
      #
      # @param client RubyAem::Client
      # @param group_name the group name of the package, e.g. somepackagegroup
      # @param package_name the name of the package, e.g. somepackage
      # @param package_version the version of the package, e.g. 1.2.3
      # @return new RubyAem::Resources::Package instance
      def initialize(client, group_name, package_name, package_version)
        @client = client
        @call_params = {
          group_name: group_name,
          package_name: package_name,
          package_version: package_version
        }
      end

      # Create the package.
      #
      # @return RubyAem::Result
      def create
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Update the package with specific filter.
      #
      # @param filter package filter JSON string
      #   example: [{ "root": "/apps/geometrixx", "rules": [] }, { "root": "/apps/geometrixx-common", "rules": []}]
      # @return RubyAem::Result
      def update(filter)
        @call_params[:filter] = filter
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Delete the package.
      #
      # @return RubyAem::Result
      def delete
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Build the package.
      #
      # @return RubyAem::Result
      def build
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Install the package without waiting until the package status states it is installed.
      #
      # @param opts optional parameters:
      # - recursive: if true then subpackages will also be installed, false otherwise
      # @return RubyAem::Result
      def install(opts = {
        recursive: true
      })
        @call_params = @call_params.merge(opts)
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Uninstall the package.
      #
      # @return RubyAem::Result
      def uninstall
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Replicate the package.
      # Package will then be added to replication agents.
      #
      # @return RubyAem::Result
      def replicate
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Download the package to a specified directory.
      #
      # @param file_path the directory where the package will be downloaded to
      # @return RubyAem::Result
      def download(file_path)
        @call_params[:file_path] = file_path
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Upload the package without waiting until the package status states it is uploaded.
      #
      # @param file_path the directory where the package file to be uploaded is
      # @param opts optional parameters:
      # - force: if false then a package file will not be uploaded when the package already exists with the same group, name, and version, default is true (will overwrite existing package file)
      # @return RubyAem::Result
      def upload(
        file_path,
        opts = {
          force: true
        }
      )
        @call_params[:file_path] = file_path
        @call_params = @call_params.merge(opts)
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Get the package filter value.
      # Filter value is stored as result data as an array of paths.
      #
      # @return RubyAem::Result
      def get_filter
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Activate all paths within a package filter.
      # Returns an array of results:
      # - the first result is the result from retrieving filter paths
      # - the rest of the results are the results from activating the filter paths, one result for each activation
      #
      # @param ignore_deactivated if true, then deactivated items in the path will not be activated
      # @param modified_only if true, then only modified items in the path will be activated
      # @return an array of RubyAem::Result
      def activate_filter(ignore_deactivated, modified_only)
        result = get_filter

        results = [result]
        result.data.each { |filter_path|
          path = RubyAem::Resources::Path.new(@client, filter_path)
          results.push(path.activate(ignore_deactivated, modified_only))
        }
        results
      end

      # List all packages available in AEM instance.
      #
      # @return RubyAem::Result
      def list_all
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Find all versions of the package
      # Result data should contain an array of version values, empty array if there's none.
      #
      # @return RubyAem::Result
      def get_versions
        packages = list_all.data
        package_versions = XPath.match(packages, "//packages/package[group=\"#{@call_params[:group_name]}\" and name=\"#{@call_params[:package_name]}\"]")

        versions = []
        package_versions.each do |package|
          version = XPath.first(package, 'version/text()')
          versions.push(version.to_s) if version.to_s != ''
        end

        message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} has #{versions.length} version(s)"
        result = RubyAem::Result.new(message, nil)
        result.data = versions

        result
      end

      # Check if this package exists.
      # True result data indicates that the package exists, false otherwise.
      #
      # @return RubyAem::Result
      def exists
        packages = list_all.data
        package = XPath.first(packages, "//packages/package[group=\"#{@call_params[:group_name]}\" and name=\"#{@call_params[:package_name]}\" and version=\"#{@call_params[:package_version]}\"]")

        if package.to_s != ''
          message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} exists"
          exists = true
        else
          message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} does not exist"
          exists = false
        end
        result = RubyAem::Result.new(message, nil)
        result.data = exists

        result
      end

      # Check if this package is uploaded. The indicator whether a package is uploaded is when it exists
      # True result data indicates that the package is uploaded, false otherwise.
      #
      # @return RubyAem::Result
      def is_uploaded
        result = exists

        result.message =
          if result.data == true
            "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is uploaded"
          else
            "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is not uploaded"
          end

        result
      end

      # Check if this package is installed.
      # True result data indicates that the package is installed, false otherwise.
      #
      # @return RubyAem::Result
      def is_installed
        packages = list_all.data
        package = XPath.first(packages, "//packages/package[group=\"#{@call_params[:group_name]}\" and name=\"#{@call_params[:package_name]}\" and version=\"#{@call_params[:package_version]}\"]")
        last_unpacked_by = XPath.first(package, 'lastUnpackedBy') if package

        if !['', '<lastUnpackedBy/>', '<lastUnpackedBy>null</lastUnpackedBy>'].include? last_unpacked_by.to_s
          message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is installed"
          is_installed = true
        else
          message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is not installed"
          is_installed = false
        end
        result = RubyAem::Result.new(message, nil)
        result.data = is_installed

        result
      end

      # Check if this package is empty (has size 0).
      # True result data indicates that the package is empty, false otherwise.
      #
      # @return RubyAem::Result
      def is_empty
        packages = list_all.data
        package = XPath.first(packages, "//packages/package[group=\"#{@call_params[:group_name]}\" and name=\"#{@call_params[:package_name]}\" and version=\"#{@call_params[:package_version]}\"]")
        size = XPath.first(package, 'size/text()').to_s.to_i

        if size.zero?
          message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is empty"
          is_empty = true
        else
          message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is not empty"
          is_empty = false
        end
        result = RubyAem::Result.new(message, nil)
        result.data = is_empty

        result
      end

      # Check if this package is built. The indicator whether a package is built is when it exists and is not empty.
      # True result data indicates that the package is built, false otherwise.
      #
      # @return RubyAem::Result
      def is_built
        exists_result = exists

        if exists_result.data == true
          is_empty_result = is_empty
          if is_empty_result.data == false
            message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is built"
            is_built = true
          else
            message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is not built because it is empty"
            is_built = false
          end
        else
          message = "Package #{@call_params[:group_name]}/#{@call_params[:package_name]}-#{@call_params[:package_version]} is not built because it does not exist"
          is_built = false
        end
        result = RubyAem::Result.new(message, nil)
        result.data = is_built

        result
      end

      # Upload the package and wait until the package status states it is uploaded.
      #
      # @param file_path the directory where the package file to be uploaded is
      # @param opts optional parameters:
      # - force: if false then a package file will not be uploaded when the package already exists with the same group, name, and version, default is true (will overwrite existing package file)
      # - _retries: retries library's options (http://www.rubydoc.info/gems/retries/0.0.5#Usage), restricted to max_tries, base_sleep_seconds, max_sleep_seconds
      # @return RubyAem::Result
      def upload_wait_until_ready(
        file_path,
        opts = {
          force: true,
          _retries: {
            max_tries: 30,
            base_sleep_seconds: 2,
            max_sleep_seconds: 2
          }
        }
      )
        opts[:force] ||= true
        opts[:_retries] ||= {}
        opts[:_retries][:max_tries] ||= 30
        opts[:_retries][:base_sleep_seconds] ||= 2
        opts[:_retries][:max_sleep_seconds] ||= 2

        # ensure integer retries setting (Puppet 3 passes numeric string)
        opts[:_retries][:max_tries] = opts[:_retries][:max_tries].to_i
        opts[:_retries][:base_sleep_seconds] = opts[:_retries][:base_sleep_seconds].to_i
        opts[:_retries][:max_sleep_seconds] = opts[:_retries][:max_sleep_seconds].to_i

        result = upload(file_path, opts)
        with_retries(max_tries: opts[:_retries][:max_tries], base_sleep_seconds: opts[:_retries][:base_sleep_seconds], max_sleep_seconds: opts[:_retries][:max_sleep_seconds]) { |retries_count|
          check_result = is_uploaded
          puts format('Upload check #%<retries_count>d: %<check_result_data>s - %<check_result_message>s', retries_count: retries_count, check_result_data: check_result.data, check_result_message: check_result.message)
          raise StandardError.new(check_result.message) if check_result.data == false
        }
        result
      end

      # Install the package and wait until the package status states it is installed.
      #
      # @param opts optional parameters:
      # - _retries: retries library's options (http://www.rubydoc.info/gems/retries/0.0.5#Usage), restricted to max_tries, base_sleep_seconds, max_sleep_seconds
      # @return RubyAem::Result
      def install_wait_until_ready(
        opts = {
          _retries: {
            max_tries: 30,
            base_sleep_seconds: 2,
            max_sleep_seconds: 2
          }
        }
      )
        opts[:_retries] ||= {}
        opts[:_retries][:max_tries] ||= 30
        opts[:_retries][:base_sleep_seconds] ||= 2
        opts[:_retries][:max_sleep_seconds] ||= 2

        # ensure integer retries setting (Puppet 3 passes numeric string)
        opts[:_retries][:max_tries] = opts[:_retries][:max_tries].to_i
        opts[:_retries][:base_sleep_seconds] = opts[:_retries][:base_sleep_seconds].to_i
        opts[:_retries][:max_sleep_seconds] = opts[:_retries][:max_sleep_seconds].to_i

        result = install
        with_retries(max_tries: opts[:_retries][:max_tries], base_sleep_seconds: opts[:_retries][:base_sleep_seconds], max_sleep_seconds: opts[:_retries][:max_sleep_seconds]) { |retries_count|
          check_result = is_installed
          puts format('Install check #%<retries_count>d: %<check_result_data>s - %<check_result_message>s', retries_count: retries_count, check_result_data: check_result.data, check_result_message: check_result.message)
          raise StandardError.new(check_result.message) if check_result.data == false
        }
        result
      end

      # Delete the package and wait until the package status states it is not uploaded.
      #
      # @param opts optional parameters:
      # - _retries: retries library's options (http://www.rubydoc.info/gems/retries/0.0.5#Usage), restricted to max_tries, base_sleep_seconds, max_sleep_seconds
      # @return RubyAem::Result
      def delete_wait_until_ready(
        opts = {
          _retries: {
            max_tries: 30,
            base_sleep_seconds: 2,
            max_sleep_seconds: 2
          }
        }
      )
        opts[:_retries] ||= {}
        opts[:_retries][:max_tries] ||= 30
        opts[:_retries][:base_sleep_seconds] ||= 2
        opts[:_retries][:max_sleep_seconds] ||= 2

        # ensure integer retries setting (Puppet 3 passes numeric string)
        opts[:_retries][:max_tries] = opts[:_retries][:max_tries].to_i
        opts[:_retries][:base_sleep_seconds] = opts[:_retries][:base_sleep_seconds].to_i
        opts[:_retries][:max_sleep_seconds] = opts[:_retries][:max_sleep_seconds].to_i

        result = delete
        with_retries(max_tries: opts[:_retries][:max_tries], base_sleep_seconds: opts[:_retries][:base_sleep_seconds], max_sleep_seconds: opts[:_retries][:max_sleep_seconds]) { |retries_count|
          check_result = is_uploaded
          puts format('Delete check #%<retries_count>d: %<check_result_data>s - %<check_result_message>s', retries_count: retries_count, check_result_data: !check_result.data, check_result_message: check_result.message)
          raise StandardError.new(check_result.message) if check_result.data == true
        }
        result
      end

      # Build the package and wait until the package status states it is built (exists and not empty).
      #
      # @param opts optional parameters:
      # - _retries: retries library's options (http://www.rubydoc.info/gems/retries/0.0.5#Usage), restricted to max_tries, base_sleep_seconds, max_sleep_seconds
      # @return RubyAem::Result
      def build_wait_until_ready(
        opts = {
          _retries: {
            max_tries: 30,
            base_sleep_seconds: 2,
            max_sleep_seconds: 2
          }
        }
      )
        opts[:_retries] ||= {}
        opts[:_retries][:max_tries] ||= 30
        opts[:_retries][:base_sleep_seconds] ||= 2
        opts[:_retries][:max_sleep_seconds] ||= 2

        # ensure integer retries setting (Puppet 3 passes numeric string)
        opts[:_retries][:max_tries] = opts[:_retries][:max_tries].to_i
        opts[:_retries][:base_sleep_seconds] = opts[:_retries][:base_sleep_seconds].to_i
        opts[:_retries][:max_sleep_seconds] = opts[:_retries][:max_sleep_seconds].to_i

        result = build
        with_retries(max_tries: opts[:_retries][:max_tries], base_sleep_seconds: opts[:_retries][:base_sleep_seconds], max_sleep_seconds: opts[:_retries][:max_sleep_seconds]) { |retries_count|
          check_result = is_built
          puts format('Build check #%<retries_count>d: %<check_result_data>s - %<check_result_message>s', retries_count: retries_count, check_result_data: check_result.data, check_result_message: check_result.message)
          raise StandardError.new(check_result.message) if check_result.data == false
        }
        result
      end
    end
  end
end
