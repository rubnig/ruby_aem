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

module RubyAem
  module Resources
    # Repository class contains API calls related to managing an AEM repository.
    class Repository
      # Initialise repository.
      #
      # @param client RubyAem::Client
      # @return new RubyAem::Resources::Repository instance
      def initialize(client)
        @client = client
        @call_params = {}
      end

      # Block repository writes.
      #
      # @return RubyAem::Result
      def block_writes
        @client.call(self.class, __callee__.to_s, @call_params)
      end

      # Unblock repository writes.
      #
      # @return RubyAem::Result
      def unblock_writes
        @client.call(self.class, __callee__.to_s, @call_params)
      end
    end
  end
end
