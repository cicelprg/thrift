#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#

require 'spec_helper'

describe 'Union' do

  describe Thrift::Union do
    it "should return nil value in unset union" do
      union = SpecNamespace::My_union.new
      expect(union.get_set_field).to eq(nil)
      expect(union.get_value).to eq(nil)
    end

    it "should set a field and be accessible through get_value and the named field accessor" do
      union = SpecNamespace::My_union.new
      union.integer32 = 25
      expect(union.get_set_field).to eq(:integer32)
      expect(union.get_value).to eq(25)
      expect(union.integer32).to eq(25)
    end

    it "should work correctly when instantiated with static field constructors" do
      union = SpecNamespace::My_union.integer32(5)
      expect(union.get_set_field).to eq(:integer32)
      expect(union.integer32).to eq(5)
    end

    it "should raise for wrong set field" do
      union = SpecNamespace::My_union.new
      union.integer32 = 25
      expect { union.some_characters }.to raise_error(RuntimeError, "some_characters is not union's set field.")
    end

    it "should raise for wrong set field when hash initialized and type checking is off" do
      Thrift.type_checking = false
      union = SpecNamespace::My_union.new({incorrect_field: :incorrect})
      expect { Thrift::Serializer.new.serialize(union) }.to raise_error(RuntimeError, "set_field is not valid for this union!")
    end

    it "should not be equal to nil" do
      union = SpecNamespace::My_union.new
      expect(union).not_to eq(nil)
    end

    it "should not be equal with an empty String" do
      union = SpecNamespace::My_union.new
      expect(union).not_to eq('')
    end

    it "should not equate two different unions, i32 vs. string" do
      union = SpecNamespace::My_union.new(:integer32, 25)
      other_union = SpecNamespace::My_union.new(:some_characters, "blah!")
      expect(union).not_to eq(other_union)
    end

    it "should properly reset setfield and setvalue" do
      union = SpecNamespace::My_union.new(:integer32, 25)
      expect(union.get_set_field).to eq(:integer32)
      union.some_characters = "blah!"
      expect(union.get_set_field).to eq(:some_characters)
      expect(union.get_value).to eq("blah!")
      expect { union.integer32 }.to raise_error(RuntimeError, "integer32 is not union's set field.")
    end

    it "should not equate two different unions with different values" do
      union = SpecNamespace::My_union.new(:integer32, 25)
      other_union = SpecNamespace::My_union.new(:integer32, 400)
      expect(union).not_to eq(other_union)
    end

    it "should not equate two different unions with different fields" do
      union = SpecNamespace::My_union.new(:integer32, 25)
      other_union = SpecNamespace::My_union.new(:other_i32, 25)
      expect(union).not_to eq(other_union)
    end

    it "should inspect properly" do
      union = SpecNamespace::My_union.new(:integer32, 25)
      expect(union.inspect).to eq("<SpecNamespace::My_union integer32: 25>")
    end

    it "should not allow setting with instance_variable_set" do
      union = SpecNamespace::My_union.new(:integer32, 27)
      union.instance_variable_set(:@some_characters, "hallo!")
      expect(union.get_set_field).to eq(:integer32)
      expect(union.get_value).to eq(27)
      expect { union.some_characters }.to raise_error(RuntimeError, "some_characters is not union's set field.")
    end

    it "should serialize to binary correctly" do
      trans = Thrift::MemoryBufferTransport.new
      proto = Thrift::BinaryProtocol.new(trans)

      union = SpecNamespace::My_union.new(:integer32, 25)
      union.write(proto)

      other_union = SpecNamespace::My_union.new(:integer32, 25)
      other_union.read(proto)
      expect(other_union).to eq(union)
    end

    it "should serialize to json correctly" do
      trans = Thrift::MemoryBufferTransport.new
      proto = Thrift::JsonProtocol.new(trans)

      union = SpecNamespace::My_union.new(:integer32, 25)
      union.write(proto)

      other_union = SpecNamespace::My_union.new(:integer32, 25)
      other_union.read(proto)
      expect(other_union).to eq(union)
    end

    it "should raise when validating unset union" do
      union = SpecNamespace::My_union.new
      expect { union.validate }.to raise_error(StandardError, "Union fields are not set.")

      other_union = SpecNamespace::My_union.new(:integer32, 1)
      expect { other_union.validate }.not_to raise_error
    end

    it "should validate an enum field properly" do
      union = SpecNamespace::TestUnion.new(:enum_field, 3)
      expect(union.get_set_field).to eq(:enum_field)
      expect { union.validate }.to raise_error(Thrift::ProtocolException, "Invalid value of field enum_field!")

      other_union = SpecNamespace::TestUnion.new(:enum_field, 1)
      expect { other_union.validate }.not_to raise_error
    end

    it "should properly serialize and match structs with a union" do
      union = SpecNamespace::My_union.new(:integer32, 26)
      swu = SpecNamespace::Struct_with_union.new(:fun_union => union)

      trans = Thrift::MemoryBufferTransport.new
      proto = Thrift::CompactProtocol.new(trans)

      swu.write(proto)

      other_union = SpecNamespace::My_union.new(:some_characters, "hello there")
      swu2 = SpecNamespace::Struct_with_union.new(:fun_union => other_union)

      expect(swu2).not_to eq(swu)

      swu2.read(proto)
      expect(swu2).to eq(swu)
    end

    it "should support old style constructor" do
      union = SpecNamespace::My_union.new(:integer32 => 26)
      expect(union.get_set_field).to eq(:integer32)
      expect(union.get_value).to eq(26)
    end

    it "should not throw an error when inspected and unset" do
      expect{SpecNamespace::TestUnion.new().inspect}.not_to raise_error
    end

    it "should print enum value name when inspected" do
      expect(SpecNamespace::My_union.new(:some_enum => SpecNamespace::SomeEnum::ONE).inspect).to eq("<SpecNamespace::My_union some_enum: ONE (0)>")

      expect(SpecNamespace::My_union.new(:my_map => {SpecNamespace::SomeEnum::ONE => [SpecNamespace::SomeEnum::TWO]}).inspect).to eq("<SpecNamespace::My_union my_map: {ONE (0): [TWO (1)]}>")
    end

    it "should offer field? methods" do
      expect(SpecNamespace::My_union.new.some_enum?).to be_falsey
      expect(SpecNamespace::My_union.new(:some_enum => SpecNamespace::SomeEnum::ONE).some_enum?).to be_truthy
      expect(SpecNamespace::My_union.new(:im_true => false).im_true?).to be_truthy
      expect(SpecNamespace::My_union.new(:im_true => true).im_true?).to be_truthy
    end

    it "should pretty print binary fields" do
      expect(SpecNamespace::TestUnion.new(:binary_field => "\001\002\003").inspect).to eq("<SpecNamespace::TestUnion binary_field: 010203>")
    end

    it "should be comparable" do
      relationships = [
        [0,   -1, -1, -1],
        [1,   0,  -1, -1],
        [1,   1,  0,  -1],
        [1,   1,  1,  0]]

      objs = [
        SpecNamespace::TestUnion.new(:string_field, "blah"),
        SpecNamespace::TestUnion.new(:string_field, "blahblah"),
        SpecNamespace::TestUnion.new(:i32_field, 1),
        SpecNamespace::TestUnion.new()]

      for y in 0..3
        for x in 0..3
          # puts "#{objs[y].inspect} <=> #{objs[x].inspect} should == #{relationships[y][x]}"
          expect(objs[y] <=> objs[x]).to eq(relationships[y][x])
        end
      end
    end
  end
end
