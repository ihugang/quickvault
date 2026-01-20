package com.quickvault.data.local.database;

import androidx.annotation.NonNull;
import androidx.room.DatabaseConfiguration;
import androidx.room.InvalidationTracker;
import androidx.room.RoomDatabase;
import androidx.room.RoomOpenHelper;
import androidx.room.migration.AutoMigrationSpec;
import androidx.room.migration.Migration;
import androidx.room.util.DBUtil;
import androidx.room.util.TableInfo;
import androidx.sqlite.db.SupportSQLiteDatabase;
import androidx.sqlite.db.SupportSQLiteOpenHelper;
import com.quickvault.data.local.database.dao.AttachmentDao;
import com.quickvault.data.local.database.dao.AttachmentDao_Impl;
import com.quickvault.data.local.database.dao.ItemDao;
import com.quickvault.data.local.database.dao.ItemDao_Impl;
import java.lang.Class;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class QuickVaultDatabase_Impl extends QuickVaultDatabase {
  private volatile ItemDao _itemDao;

  private volatile AttachmentDao _attachmentDao;

  @Override
  @NonNull
  protected SupportSQLiteOpenHelper createOpenHelper(@NonNull final DatabaseConfiguration config) {
    final SupportSQLiteOpenHelper.Callback _openCallback = new RoomOpenHelper(config, new RoomOpenHelper.Delegate(3) {
      @Override
      public void createAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS `items` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, `type` TEXT NOT NULL, `tags_json` TEXT NOT NULL, `is_pinned` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, `updated_at` INTEGER NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_items_title` ON `items` (`title`)");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_items_type` ON `items` (`type`)");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_items_is_pinned` ON `items` (`is_pinned`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS `item_texts` (`id` TEXT NOT NULL, `item_id` TEXT NOT NULL, `encrypted_content` BLOB NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY(`id`), FOREIGN KEY(`item_id`) REFERENCES `items`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_item_texts_item_id` ON `item_texts` (`item_id`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS `attachments` (`id` TEXT NOT NULL, `item_id` TEXT NOT NULL, `file_name` TEXT NOT NULL, `file_type` TEXT NOT NULL, `file_size` INTEGER NOT NULL, `display_order` INTEGER NOT NULL, `encrypted_file_path` TEXT NOT NULL, `thumbnail_file_path` TEXT, `created_at` INTEGER NOT NULL, PRIMARY KEY(`id`), FOREIGN KEY(`item_id`) REFERENCES `items`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_attachments_item_id` ON `attachments` (`item_id`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)");
        db.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, '9fc5c8210cd9a24bbb1c6cfa516f14d2')");
      }

      @Override
      public void dropAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("DROP TABLE IF EXISTS `items`");
        db.execSQL("DROP TABLE IF EXISTS `item_texts`");
        db.execSQL("DROP TABLE IF EXISTS `attachments`");
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onDestructiveMigration(db);
          }
        }
      }

      @Override
      public void onCreate(@NonNull final SupportSQLiteDatabase db) {
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onCreate(db);
          }
        }
      }

      @Override
      public void onOpen(@NonNull final SupportSQLiteDatabase db) {
        mDatabase = db;
        db.execSQL("PRAGMA foreign_keys = ON");
        internalInitInvalidationTracker(db);
        final List<? extends RoomDatabase.Callback> _callbacks = mCallbacks;
        if (_callbacks != null) {
          for (RoomDatabase.Callback _callback : _callbacks) {
            _callback.onOpen(db);
          }
        }
      }

      @Override
      public void onPreMigrate(@NonNull final SupportSQLiteDatabase db) {
        DBUtil.dropFtsSyncTriggers(db);
      }

      @Override
      public void onPostMigrate(@NonNull final SupportSQLiteDatabase db) {
      }

      @Override
      @NonNull
      public RoomOpenHelper.ValidationResult onValidateSchema(
          @NonNull final SupportSQLiteDatabase db) {
        final HashMap<String, TableInfo.Column> _columnsItems = new HashMap<String, TableInfo.Column>(7);
        _columnsItems.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItems.put("title", new TableInfo.Column("title", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItems.put("type", new TableInfo.Column("type", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItems.put("tags_json", new TableInfo.Column("tags_json", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItems.put("is_pinned", new TableInfo.Column("is_pinned", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItems.put("created_at", new TableInfo.Column("created_at", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItems.put("updated_at", new TableInfo.Column("updated_at", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysItems = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesItems = new HashSet<TableInfo.Index>(3);
        _indicesItems.add(new TableInfo.Index("index_items_title", false, Arrays.asList("title"), Arrays.asList("ASC")));
        _indicesItems.add(new TableInfo.Index("index_items_type", false, Arrays.asList("type"), Arrays.asList("ASC")));
        _indicesItems.add(new TableInfo.Index("index_items_is_pinned", false, Arrays.asList("is_pinned"), Arrays.asList("ASC")));
        final TableInfo _infoItems = new TableInfo("items", _columnsItems, _foreignKeysItems, _indicesItems);
        final TableInfo _existingItems = TableInfo.read(db, "items");
        if (!_infoItems.equals(_existingItems)) {
          return new RoomOpenHelper.ValidationResult(false, "items(com.quickvault.data.local.database.entity.ItemEntity).\n"
                  + " Expected:\n" + _infoItems + "\n"
                  + " Found:\n" + _existingItems);
        }
        final HashMap<String, TableInfo.Column> _columnsItemTexts = new HashMap<String, TableInfo.Column>(4);
        _columnsItemTexts.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItemTexts.put("item_id", new TableInfo.Column("item_id", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItemTexts.put("encrypted_content", new TableInfo.Column("encrypted_content", "BLOB", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsItemTexts.put("created_at", new TableInfo.Column("created_at", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysItemTexts = new HashSet<TableInfo.ForeignKey>(1);
        _foreignKeysItemTexts.add(new TableInfo.ForeignKey("items", "CASCADE", "NO ACTION", Arrays.asList("item_id"), Arrays.asList("id")));
        final HashSet<TableInfo.Index> _indicesItemTexts = new HashSet<TableInfo.Index>(1);
        _indicesItemTexts.add(new TableInfo.Index("index_item_texts_item_id", false, Arrays.asList("item_id"), Arrays.asList("ASC")));
        final TableInfo _infoItemTexts = new TableInfo("item_texts", _columnsItemTexts, _foreignKeysItemTexts, _indicesItemTexts);
        final TableInfo _existingItemTexts = TableInfo.read(db, "item_texts");
        if (!_infoItemTexts.equals(_existingItemTexts)) {
          return new RoomOpenHelper.ValidationResult(false, "item_texts(com.quickvault.data.local.database.entity.TextContentEntity).\n"
                  + " Expected:\n" + _infoItemTexts + "\n"
                  + " Found:\n" + _existingItemTexts);
        }
        final HashMap<String, TableInfo.Column> _columnsAttachments = new HashMap<String, TableInfo.Column>(9);
        _columnsAttachments.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("item_id", new TableInfo.Column("item_id", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("file_name", new TableInfo.Column("file_name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("file_type", new TableInfo.Column("file_type", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("file_size", new TableInfo.Column("file_size", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("display_order", new TableInfo.Column("display_order", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("encrypted_file_path", new TableInfo.Column("encrypted_file_path", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("thumbnail_file_path", new TableInfo.Column("thumbnail_file_path", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("created_at", new TableInfo.Column("created_at", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysAttachments = new HashSet<TableInfo.ForeignKey>(1);
        _foreignKeysAttachments.add(new TableInfo.ForeignKey("items", "CASCADE", "NO ACTION", Arrays.asList("item_id"), Arrays.asList("id")));
        final HashSet<TableInfo.Index> _indicesAttachments = new HashSet<TableInfo.Index>(1);
        _indicesAttachments.add(new TableInfo.Index("index_attachments_item_id", false, Arrays.asList("item_id"), Arrays.asList("ASC")));
        final TableInfo _infoAttachments = new TableInfo("attachments", _columnsAttachments, _foreignKeysAttachments, _indicesAttachments);
        final TableInfo _existingAttachments = TableInfo.read(db, "attachments");
        if (!_infoAttachments.equals(_existingAttachments)) {
          return new RoomOpenHelper.ValidationResult(false, "attachments(com.quickvault.data.local.database.entity.AttachmentEntity).\n"
                  + " Expected:\n" + _infoAttachments + "\n"
                  + " Found:\n" + _existingAttachments);
        }
        return new RoomOpenHelper.ValidationResult(true, null);
      }
    }, "9fc5c8210cd9a24bbb1c6cfa516f14d2", "a7eafb2c59aa5627524f7fbeeaaff981");
    final SupportSQLiteOpenHelper.Configuration _sqliteConfig = SupportSQLiteOpenHelper.Configuration.builder(config.context).name(config.name).callback(_openCallback).build();
    final SupportSQLiteOpenHelper _helper = config.sqliteOpenHelperFactory.create(_sqliteConfig);
    return _helper;
  }

  @Override
  @NonNull
  protected InvalidationTracker createInvalidationTracker() {
    final HashMap<String, String> _shadowTablesMap = new HashMap<String, String>(0);
    final HashMap<String, Set<String>> _viewTables = new HashMap<String, Set<String>>(0);
    return new InvalidationTracker(this, _shadowTablesMap, _viewTables, "items","item_texts","attachments");
  }

  @Override
  public void clearAllTables() {
    super.assertNotMainThread();
    final SupportSQLiteDatabase _db = super.getOpenHelper().getWritableDatabase();
    final boolean _supportsDeferForeignKeys = android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP;
    try {
      if (!_supportsDeferForeignKeys) {
        _db.execSQL("PRAGMA foreign_keys = FALSE");
      }
      super.beginTransaction();
      if (_supportsDeferForeignKeys) {
        _db.execSQL("PRAGMA defer_foreign_keys = TRUE");
      }
      _db.execSQL("DELETE FROM `items`");
      _db.execSQL("DELETE FROM `item_texts`");
      _db.execSQL("DELETE FROM `attachments`");
      super.setTransactionSuccessful();
    } finally {
      super.endTransaction();
      if (!_supportsDeferForeignKeys) {
        _db.execSQL("PRAGMA foreign_keys = TRUE");
      }
      _db.query("PRAGMA wal_checkpoint(FULL)").close();
      if (!_db.inTransaction()) {
        _db.execSQL("VACUUM");
      }
    }
  }

  @Override
  @NonNull
  protected Map<Class<?>, List<Class<?>>> getRequiredTypeConverters() {
    final HashMap<Class<?>, List<Class<?>>> _typeConvertersMap = new HashMap<Class<?>, List<Class<?>>>();
    _typeConvertersMap.put(ItemDao.class, ItemDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(AttachmentDao.class, AttachmentDao_Impl.getRequiredConverters());
    return _typeConvertersMap;
  }

  @Override
  @NonNull
  public Set<Class<? extends AutoMigrationSpec>> getRequiredAutoMigrationSpecs() {
    final HashSet<Class<? extends AutoMigrationSpec>> _autoMigrationSpecsSet = new HashSet<Class<? extends AutoMigrationSpec>>();
    return _autoMigrationSpecsSet;
  }

  @Override
  @NonNull
  public List<Migration> getAutoMigrations(
      @NonNull final Map<Class<? extends AutoMigrationSpec>, AutoMigrationSpec> autoMigrationSpecs) {
    final List<Migration> _autoMigrations = new ArrayList<Migration>();
    return _autoMigrations;
  }

  @Override
  public ItemDao itemDao() {
    if (_itemDao != null) {
      return _itemDao;
    } else {
      synchronized(this) {
        if(_itemDao == null) {
          _itemDao = new ItemDao_Impl(this);
        }
        return _itemDao;
      }
    }
  }

  @Override
  public AttachmentDao attachmentDao() {
    if (_attachmentDao != null) {
      return _attachmentDao;
    } else {
      synchronized(this) {
        if(_attachmentDao == null) {
          _attachmentDao = new AttachmentDao_Impl(this);
        }
        return _attachmentDao;
      }
    }
  }
}
