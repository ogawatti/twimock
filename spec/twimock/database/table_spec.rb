require 'spec_helper'

describe Twimock::Database::Table do
  include TableHelper

  let(:db_name)      { ".test" }
  let(:table_name)   { :tables }
  let(:column_names) { [ :id, :text, :active, :number, :created_at ] }
  let(:children)     { [] }

  before do
    stub_const("Twimock::Database::DEFAULT_DB_NAME", db_name)
    create_tables_table_for_test
  end

  after do
    Twimock::Database.new.drop
    remove_dynamically_defined_all_method
  end

  describe '::TABLE_NAME' do
    subject { Twimock::Database::Table::TABLE_NAME }
    it { is_expected.to eq table_name }
  end

  describe '::COLUMN_NAMES' do
    subject { Twimock::Database::Table::COLUMN_NAMES }
    it { is_expected.to eq column_names }
  end

  describe '::CHILDREN' do
    subject { Twimock::Database::Table::CHILDREN }
    it { is_expected.to eq children }
  end

  describe '#initialize' do
    context 'without option' do
      it 'should have accessor of column' do
        @table = Twimock::Database::Table.new
        column_names.each do |column_name|
           if column_name == :active
             expect(@table.send(column_name)).to be false
           else
             expect(@table.send(column_name)).to be_nil
           end
        end

        @table.id = id = 1
        @table.text = text = "test"
        @table.active = active = true
        @table.number = number = 0
        @table.created_at = created_at = Time.now
        expect(@table.id).to eq id
        expect(@table.text).to eq text
        expect(@table.active).to eq active
        expect(@table.number).to eq number
        expect(@table.created_at).to eq created_at 

        expect(lambda{ @table.name }).to raise_error NoMethodError
        expect(lambda{ @table.name = nil }).to raise_error NoMethodError
      end
    end

    context 'with option' do
      it 'should have accessor of column' do
        options = { id: 1, text: "test", active: true, number: 0, created_at: Time.now }
        @table = Twimock::Database::Table.new(options)
        options.each_key do |key|
          expect(@table.send(key)).to eq options[key]
        end
      end
    end
  end

  describe '#save!' do
    before { @table = Twimock::Database::Table.new }

    context 'when text does not set value' do
      subject { lambda { @table.save! } }
      it { is_expected.to raise_error }
    end

    context 'when text and number set value' do
      before do
        @table.text   = @text   = "test"
        @table.number = @number = 0
      end

      context 'without option' do
        context 'when id and created_at are nil' do
          it 'should set value to id and created_at' do
            expect(@table.id).to be_nil
            expect(@table.text).to eq @text
            expect(@table.active).to eq false
            expect(@table.number).to eq @number
            expect(@table.created_at).to be_nil
            @table.save!
            expect(@table.id).to be > 0
            expect(@table.text).to eq @text
            expect(@table.active).to eq false
            expect(@table.number).to eq @number
            expect(@table.created_at).to be <= Time.now
          end
        end

        context 'when id is specified but record does not exist' do
          before { @table.id = @id = 1 }

          it 'should set value to created_at and id does not change' do
            expect(@table.id).to eq @id
            expect(@table.text).to eq @text
            expect(@table.active).to eq false
            expect(@table.number).to eq @number
            expect(@table.created_at).to be_nil
            @table.save!
            expect(@table.id).to eq @id
            expect(@table.text).to eq @text
            expect(@table.active).to eq false
            expect(@table.number).to eq @number
            expect(@table.created_at).to be <= Time.now
          end
        end

        context 'when id is specified and record exists' do
          before { @table.save! }

          it 'should not change id and created_at' do
            id = @table.id
            created_at = @table.created_at
            @table.save!
            expect(@table.id).to eq id
            expect(@table.created_at).to eq created_at
          end
        end
      end

      context 'with option' do
        context 'that are id and text, active, number, created_at' do
          context 'instance attributes does not set values without text' do
            before do
              @id = 100
              @text = "hogehoge"
              @active = true
              @number = 0
              @created_at = Time.now + 1000
              @options = { id: @id, text: @text, active: @active, number: @number, created_at: @created_at }
            end

            it 'should set specified value by option withou created_at' do
              @table.save!(@options)
              expect(@table.id).to eq @id
              expect(@table.text).to eq @text
              expect(@table.active).to eq @active
              expect(@table.number).to eq @number
              expect(@table.created_at).not_to eq @created_at
            end
          end

          context 'instance all attributes set values' do
            before do
              @table.id = @setting_id = 10
              @setting_text = @text
              @setting_active = @active
              @setting_number = @number
              @table.created_at = @setting_created_at = Time.now - 1000
              @options_id = 100
              @options_text = "hogehoge"
              @options_active = false
              @options_number = 1
              @options_created_at = Time.now + 1000
              @options = { id: @options_id,
                           text: @options_text,
                           active: @options_active,
                           number: @options_number,
                           created_at: @options_created_at }
            end

            it 'should set specified value by option withou created_at' do
              @table.save!(@options)
              expect(@table.id).to eq @options_id
              expect(@table.text).to eq @options_text
              expect(@table.active).to eq @options_active
              expect(@table.number).to eq @options_number
              expect(@table.created_at).not_to eq @options_created_at
              expect(@table.created_at).not_to eq @setting_created_at
            end
          end
        end
      end
    end
  end

  describe '#create!' do
    context 'without option' do
      subject { lambda { Twimock::Database::Table.create! } }
      it { is_expected.to raise_error Twimock::Errors::ColumnTypeNotNull }
    end

    context 'with options that cloumns are not null' do
      before do
        @options = { id: 1, text: "test", active: true, number: 0, created_at: Time.now }
      end

      it 'should new and save and return saved object' do
        table = Twimock::Database::Table.create!(@options)
        expect(table).to be_kind_of(Twimock::Database::Table)
        column_names.each do |column_name|
          value = table.send(column_name)
          if column_name == :created_at
            expect(value).to be_kind_of Time
          else
            expect(value).to eq @options[column_name]
          end
        end
      end
    end
  end

  describe '#update_attributes!' do
    before { @table = Twimock::Database::Table.new({text: "test", number: 1}) }

    context 'without options' do
      subject { lambda { @table.update_attributes! } }
      it { is_expected.to raise_error ArgumentError }
    end

    context 'with options' do
      context 'before save!' do
        subject { @table.update_attributes!({ created_at: Time.now }) }
        it { is_expected.to eq true }

        context 'that does not include column name' do
          before { @options = { hoge: "hoge" } }
          subject { lambda { @table.update_attributes!(@options) } }
          it { is_expected.to raise_error NoMethodError }
        end

        context 'that is id' do
          it 'should set specified value by option' do
            id = 100
            @table.update_attributes!({ id: id })
            expect(id).to eq id
          end

          it 'should set specified value by option when instance id is set' do
            @table.id = 10
            id = 100
            @table.update_attributes!({ id: id })
            expect(id).to eq id
          end
        end

        context 'that is text' do
          context 'but instance does not set value to text' do
            it 'should change created_at value' do
              table = Twimock::Database::Table.new
              expect(lambda { table.update_attributes!({ text: "test" }) }).to raise_error
            end
          end

          context 'but instance is set value to text' do
            it 'should not change created_at value' do
              text = "text"
              table = Twimock::Database::Table.new({ text: text, number: 1 })
              table.update_attributes!({ text: text })
              expect(table.text).to eq text
            end
          end
        end

        context 'that is created_at' do
          it 'should ignore the value' do
            created_at = Time.now + 60
            @table.update_attributes!({ created_at: created_at })
            expect(@table.created_at).not_to eq created_at
          end
        end
      end

      context 'after save!' do
        before { @table.save! }

        subject { @table.update_attributes!({ created_at: @table.created_at + 60 }) }
        it { is_expected.to eq true }

        context 'with option that does not include column name' do
          before { @options = { hoge: "hoge" } }
          subject { lambda { @table.update_attributes!(@options) } }
          it { is_expected.to raise_error NoMethodError }
        end

        context 'when any column values does not change' do
          it 'should not change created_at value' do
            created_at = @table.created_at
            @table.update_attributes!({ created_at: created_at })
            expect(@table.created_at).to eq created_at
          end
        end

        context 'when created_at column changes' do
          it 'should change created_at value' do
            created_at = @table.created_at + 60
            @table.update_attributes!({ created_at: created_at })
            expect(@table.created_at).to eq created_at
          end
        end
      end
    end
  end

  describe '#persisted?' do
    before do
      @table = Twimock::Database::Table.new({ text: "test", number: 1 })
    end

    context 'before save' do
      subject { @table.persisted? }
      it { is_expected.to be false }
    end

    context 'after save' do
      before { @table.save! }
      subject { @table.persisted? }
      it { is_expected.to be true }
    end
  end

  describe '#destroy!' do
    before { @table = Twimock::Database::Table.new({ text: "test", number: 1 }) }

    context 'before record is saved' do
      subject { lambda { @table.destroy } }
      it { is_expected.to raise_error RuntimeError }
    end

    context 'after records is saved' do
      before { @table.save! }
      subject { lambda { @table.destroy } }
      it { is_expected.not_to raise_error }
    end

    context 'when tables table has two record' do
      before do
        @table.save!
        Twimock::Database::Table.new({text: "test", number: 1}).save!
      end

      it 'should delete one record' do
        expect(Twimock::Database::Table.all.count).to eq 2
        @table.destroy
        expect(Twimock::Database::Table.all.count).to eq 1
        expect(Twimock::Database::Table.find_by_id(@table.id)).to eq nil
      end
    end
  end

  describe '.all' do
    context 'when tables record does not exist' do
      subject { Twimock::Database::Table.all }

      it { is_expected.to be_kind_of Array }
      it { is_expected.to be_empty }
    end

    context 'when tables record exists' do
      before do
        @ids = 3.times.inject([]) do |ary, i| 
          table = Twimock::Database::Table.new({text: "test", number: 1})
          table.save!
          ary << table.id
        end
      end

      it 'should be array and should have three Table instances' do
        tables = Twimock::Database::Table.all
        expect(tables).to be_kind_of Array
        expect(tables.count).to eq 3
        tables.each do |table|
          expect(table).to be_kind_of Twimock::Database::Table
          expect(@ids).to be_include table.id
        end
      end
    end
  end

  describe '.first' do
    context 'when tables record does not exist' do
      subject { Twimock::Database::Table.first }
      it { is_expected.to be_nil }
    end

    context 'when tables record exists' do
      before do
        @ids = 3.times.inject([]) do |ary, i| 
          table = Twimock::Database::Table.new({text: "test", number: 1})
          table.save!
          ary << table.id
        end
      end

      it 'should be Table instances and id is the smallest' do
        finded = Twimock::Database::Table.first
        expect(finded).to be_kind_of Twimock::Database::Table
        expect(finded.id).to eq @ids.sort.first
      end
    end
  end

  describe '.last' do
    context 'when tables record does not exist' do
      subject { Twimock::Database::Table.last }
      it { is_expected.to be_nil }
    end

    context 'when tables record exists' do
      before do
        @ids = 3.times.inject([]) do |ary, i| 
          table = Twimock::Database::Table.new({text: "test", number: 1})
          table.save!
          ary << table.id
        end
      end

      it 'should be Table instances and id is biggest' do
        finded = Twimock::Database::Table.last
        expect(finded).to be_kind_of Twimock::Database::Table
        expect(finded.id).to eq @ids.sort.last
      end
    end
  end

  describe '.where' do
    context 'when tables record does not exist' do
      subject { Twimock::Database::Table.where(id: 1) }
      it { is_expected.to be_kind_of Array }
      it { is_expected.to be_empty }
    end

    context 'when tables record exists' do
      before do
        @ids = 3.times.inject([]) do |ary, i| 
          table = Twimock::Database::Table.new({text: "test", number: 1})
          table.save!
          ary << table.id
        end
      end

      it 'should be Array and should have only a Table instances' do
        @ids.each do |id|
          finded = Twimock::Database::Table.where(id: id)
          expect(finded).to be_kind_of Array
          expect(finded.count).to eq 1
          expect(finded.first).to be_kind_of Twimock::Database::Table
          expect(finded.first.id).to eq id
        end
      end
    end
  end

  describe '.method_missing' do
    context 'method name does not include find_by and find_all_by' do
      subject { lambda { Twimock::Database::Table.find_hoge } }
      it { is_expected.to raise_error NoMethodError }
    end

    context 'method name does not inlcude column name' do
      context 'without argument' do
        subject { lambda { Twimock::Database::Table.find_by_hoge } }
        it { is_expected.to raise_error NoMethodError }
      end

      context 'with argument' do
        subject { lambda { Twimock::Database::Table.find_by_hoge("hoge") } }
        it { is_expected.to raise_error NoMethodError }
      end
    end

    context 'method name inlcudes by_column_name' do
      context 'without argument' do
        subject { lambda { Twimock::Database::Table.find_by_id } }
        it { is_expected.to raise_error ArgumentError }
      end

      describe '.find_by_id' do
        context 'with nil' do
          subject { Twimock::Database::Table.find_by_id(nil) }
          it { is_expected.to be_nil }
        end

        context 'with not id' do
          subject { Twimock::Database::Table.find_by_id("hoge") }
          it { is_expected.to be_nil }
        end

        context 'with id' do
          context 'when record does not exist' do
            subject { Twimock::Database::Table.find_by_id(1) }
            it { is_expected.to be_nil }
          end

          context 'when record exists' do
            it 'should be Table instance' do
              created = Twimock::Database::Table.new({text: "test", number: 1})
              created.save!
              finded  = Twimock::Database::Table.find_by_id(created.id)
              expect(finded).to be_kind_of Twimock::Database::Table
              expect(finded.id).to eq created.id
              finded.instance_variables.each do |key|
                expect(finded.instance_variable_get(key)).to eq created.instance_variable_get(key)
              end
            end
          end
        end
      end

      describe '.find_by_created_at' do
        context 'with not created_at' do
          subject { Twimock::Database::Table.find_by_created_at("hoge") }
          it { is_expected.to be_nil }
        end

        context 'with created_at' do
          context 'when record does not exist' do
            subject { Twimock::Database::Table.find_by_created_at(Time.now) }
            it { is_expected.to be_nil }
          end

          context 'when record exists' do
            it 'should be Table instance' do
              created = Twimock::Database::Table.new({text: "test", number: 1})
              created.save!
              finded  = Twimock::Database::Table.find_by_created_at(created.created_at)
              expect(finded).to be_kind_of Twimock::Database::Table
              expect(finded.id).to eq created.id
              finded.instance_variables.each do |key|
                expect(finded.instance_variable_get(key)).to eq created.instance_variable_get(key)
              end
            end
          end
        end
      end
    end

    context 'method name includes find_all_by_column_name' do
      context 'without argument' do
        subject { lambda { Twimock::Database::Table.find_all_by_id } }
        it { is_expected.to raise_error ArgumentError }
      end

      describe '.find_all_by_id' do
        context 'with nil' do
          subject { Twimock::Database::Table.find_all_by_id(nil) }
          it { is_expected.to be_empty }
        end

        context 'with not id' do
          subject { Twimock::Database::Table.find_all_by_id("hoge") }
          it { is_expected.to be_empty }
        end

        context 'with id' do
          context 'when record does not exist' do
            subject { Twimock::Database::Table.find_all_by_id(1) }
            it { is_expected.to be_empty }
          end

          context 'when record exists' do
            it 'should be array and should have only one Table instances' do
              created = Twimock::Database::Table.new({text: "test", number: 1})
              created.save!
              tables  = Twimock::Database::Table.find_all_by_id(created.id)
              expect(tables).to be_kind_of Array
              expect(tables.count).to eq 1
              tables.each do |finded|
                finded.instance_variables.each do |key|
                  expect(finded.instance_variable_get(key)).to eq created.instance_variable_get(key)
                end
              end
            end
          end
        end
      end

      describe '.find_all_by_created_at' do
        context 'with not created_at' do
          subject { Twimock::Database::Table.find_all_by_created_at("hoge") }
          it { is_expected.to be_empty }
        end

        context 'with created_at' do
          context 'when record does not exist' do
            subject { Twimock::Database::Table.find_all_by_created_at(Time.now) }
            it { is_expected.to be_empty }
          end

          context 'when record exists' do
            it 'should be Table instance' do
              created = Twimock::Database::Table.new({text: "test", number: 1})
              created.save!
              created_at = created.created_at
              updated = Twimock::Database::Table.new({text: "test", number: 1})
              updated.save!
              updated.created_at = created_at
              updated.save!

              tables = Twimock::Database::Table.find_all_by_created_at(created_at)
              expect(tables).to be_kind_of Array
              expect(tables.count).to eq 2
              tables.each do |finded|
                expect(finded).to be_kind_of Twimock::Database::Table
                expect(finded.created_at).to eq created_at
              end
            end
          end
        end
      end
    end
  end

  describe '#method_missing' do
    before do
      @table = Twimock::Database::Table.new({text: "test", number: 1})
      @table.save!
    end

    context 'when method is getter' do
      describe '#id' do
        subject { @table.id }
        it { is_expected.to be_kind_of Integer }
      end

      describe '#identifier' do
        subject { @table.identifier }
        it { is_expected.to eq @table.id }
      end
    end

    context 'when method is setter' do
      describe '#id=' do
        before { @id = 1 }
          
        it 'should set attribute to id' do
          expect(@table.id).to be_kind_of Integer
          @table.id = @id
          expect(@table.id).to eq @id
        end
      end

      describe '#identifier=' do
        before { @id = 1 }

        it 'should set attribute to id' do
          expect(@table.identifier).to be_kind_of Integer
          @table.identifier = @id
          expect(@table.id).to eq @id
          expect(@table.identifier).to eq @table.id
        end
      end
    end
  end

  describe '.table_info' do
    subject { Twimock::Database::Table.table_info }
    it { is_expected.to be_kind_of Hashie::Mash }

    it 'has keys that is id and created_at' do
      table_info = Twimock::Database::Table.table_info
      table_info.each_keys do |key|
        expect(key.to_sym).to include column_names
      end
    end

    context 'then keys' do
      before { @table_info = Twimock::Database::Table.table_info }

      describe '#id' do
        subject { @table_info.id }
        it { is_expected.to be_kind_of Hashie::Mash }

        it 'should have column_info' do
          expect(@table_info.id.cid).to eq 0
          expect(@table_info.id.name).to eq :id
          expect(@table_info.id.type).to eq "INTEGER"
          expect(@table_info.id.notnull).to eq false
          expect(@table_info.id.dflt_value).to be_nil
          expect(@table_info.id.pk).to eq true
        end
      end

      describe '#text' do
        subject { @table_info.created_at }
        it { is_expected.to be_kind_of Hashie::Mash }

        it 'should have column_info' do
          expect(@table_info.text.cid).to eq 1
          expect(@table_info.text.name).to eq :text
          expect(@table_info.text.type).to eq "TEXT"
          expect(@table_info.text.notnull).to eq true
          expect(@table_info.text.dflt_value).to be_nil
          expect(@table_info.text.pk).to eq false
        end
      end
        
      describe '#active' do
        subject { @table_info.active }
        it { is_expected.to be_kind_of Hashie::Mash }

        it 'should have column_info' do
          expect(@table_info.active.cid).to eq 2
          expect(@table_info.active.name).to eq :active
          expect(@table_info.active.type).to eq "BOOLEAN"
          expect(@table_info.active.notnull).to eq false
          expect(@table_info.active.dflt_value).to be_nil
          expect(@table_info.active.pk).to eq false
        end
      end

      describe '#number' do
        subject { @table_info.number }
        it { is_expected.to be_kind_of Hashie::Mash }

        it 'should have column_info' do
          expect(@table_info.number.cid).to eq 3
          expect(@table_info.number.name).to eq :number
          expect(@table_info.number.type).to eq "INTEGER"
          expect(@table_info.number.notnull).to eq true
          expect(@table_info.number.dflt_value).to be_nil
          expect(@table_info.number.pk).to eq false
        end
      end
        
      describe '#created_at' do
        subject { @table_info.created_at }
        it { is_expected.to be_kind_of Hashie::Mash }

        it 'should have column_info' do
          expect(@table_info.created_at.cid).to eq 4
          expect(@table_info.created_at.name).to eq :created_at
          expect(@table_info.created_at.type).to eq "DATETIME"
          expect(@table_info.created_at.notnull).to eq true
          expect(@table_info.created_at.dflt_value).to be_nil
          expect(@table_info.created_at.pk).to eq false
        end
      end
    end
  end

  describe '.column_type' do
    context 'without argument' do
      subject { lambda { Twimock::Database::Table.column_type } }
      it { is_expected.to raise_error ArgumentError }
    end

    context 'with not column name' do
      subject { Twimock::Database::Table.column_type(:hoge) }
      it { is_expected.to be_nil }
    end

    context 'with id' do
      subject { Twimock::Database::Table.column_type(:id) }
      it { is_expected.to eq "INTEGER" }
    end

    context 'with created_at' do
      subject { Twimock::Database::Table.column_type(:created_at) }
      it { is_expected.to eq "DATETIME" }
    end
  end
end
