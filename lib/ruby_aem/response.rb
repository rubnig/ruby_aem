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
  # Response wraps HTTP response data returned by swagger_aem.
  class Response
    attr_accessor :status_code
    attr_accessor :body
    attr_accessor :headers

    # Initialise a result.
    #
    # @param status_code HTTP status code
    # @param body HTTP response body
    # @param headers HTTP headers
    # @return new RubyAem::Response instance
    def initialize(status_code, body, headers)
      @status_code = status_code
      @body = body
      @headers = headers
    end
  end
end
