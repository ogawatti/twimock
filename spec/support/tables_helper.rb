module TableHelper
  def remove_dynamically_defined_all_method
    klasses = [Twimock::Database::Table]
    klasses.each do |klass|
      remove_dynamically_defined_class_method(klass)
      remove_dynamically_defined_instance_method(klass)
    end
  end

  # テストで動的に定義したクラスメソッドを削除
  def remove_dynamically_defined_class_method(klass)
    klass.methods.each do |method_name|
      if method_name.to_s =~ /^find_by_/ || method_name.to_s =~ /^find_all_by_/
        klass.class_eval do
          class_variable_set(:@@target_method_name, method_name)
          class << self
            remove_method class_variable_get(:@@target_method_name)
          end
          remove_class_variable(:@@target_method_name)
        end
      end
    end
  end

  # テストで動的に定義したインスタンスメソッドを削除
  def remove_dynamically_defined_instance_method(klass)
    klass.column_names.each do |column_name|
      getter = column_name
      if klass.instance_methods.include?(getter)
        klass.class_eval { remove_method getter }
      end

      setter = (column_name.to_s + "=").to_sym
      if klass.instance_methods.include?(setter)
        klass.class_eval { remove_method setter }
      end
    end
  end

  # Tableクラスでテストするために、一時的にDB Tableを作成する
  def create_tables_table_for_test
    db = Twimock::Database.new
    db.connection.execute <<-SQL
      CREATE TABLE TABLES (
        id          INTEGER   PRIMARY KEY AUTOINCREMENT,
        text        TEXT      NOT NULL,
        active      BOOLEAN,
        number      INTEGER   NOT NULL,
        created_at  DATETIME  NOT NULL
      );
    SQL
    db.disconnect!
  end
end
