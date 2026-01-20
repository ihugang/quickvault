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
import com.quickvault.data.local.database.dao.CardDao;
import com.quickvault.data.local.database.dao.CardDao_Impl;
import com.quickvault.data.local.database.dao.CardFieldDao;
import com.quickvault.data.local.database.dao.CardFieldDao_Impl;
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
  private volatile CardDao _cardDao;

  private volatile CardFieldDao _cardFieldDao;

  private volatile AttachmentDao _attachmentDao;

  @Override
  @NonNull
  protected SupportSQLiteOpenHelper createOpenHelper(@NonNull final DatabaseConfiguration config) {
    final SupportSQLiteOpenHelper.Callback _openCallback = new RoomOpenHelper(config, new RoomOpenHelper.Delegate(1) {
      @Override
      public void createAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS `cards` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, `card_type` TEXT NOT NULL, `group` TEXT NOT NULL, `is_pinned` INTEGER NOT NULL, `tags_json` TEXT NOT NULL, `created_at` INTEGER NOT NULL, `updated_at` INTEGER NOT NULL, PRIMARY KEY(`id`))");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_cards_title` ON `cards` (`title`)");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_cards_group` ON `cards` (`group`)");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_cards_is_pinned` ON `cards` (`is_pinned`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS `card_fields` (`id` TEXT NOT NULL, `card_id` TEXT NOT NULL, `label` TEXT NOT NULL, `encrypted_value` BLOB NOT NULL, `is_required` INTEGER NOT NULL, `display_order` INTEGER NOT NULL, PRIMARY KEY(`id`), FOREIGN KEY(`card_id`) REFERENCES `cards`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_card_fields_card_id` ON `card_fields` (`card_id`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS `attachments` (`id` TEXT NOT NULL, `card_id` TEXT NOT NULL, `file_name` TEXT NOT NULL, `file_type` TEXT NOT NULL, `file_size` INTEGER NOT NULL, `encrypted_data` BLOB NOT NULL, `thumbnail_data` BLOB, `created_at` INTEGER NOT NULL, PRIMARY KEY(`id`), FOREIGN KEY(`card_id`) REFERENCES `cards`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )");
        db.execSQL("CREATE INDEX IF NOT EXISTS `index_attachments_card_id` ON `attachments` (`card_id`)");
        db.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)");
        db.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, 'b06c2b631c168c9d8344da95f17a5cd0')");
      }

      @Override
      public void dropAllTables(@NonNull final SupportSQLiteDatabase db) {
        db.execSQL("DROP TABLE IF EXISTS `cards`");
        db.execSQL("DROP TABLE IF EXISTS `card_fields`");
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
        final HashMap<String, TableInfo.Column> _columnsCards = new HashMap<String, TableInfo.Column>(8);
        _columnsCards.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCards.put("title", new TableInfo.Column("title", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCards.put("card_type", new TableInfo.Column("card_type", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCards.put("group", new TableInfo.Column("group", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCards.put("is_pinned", new TableInfo.Column("is_pinned", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCards.put("tags_json", new TableInfo.Column("tags_json", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCards.put("created_at", new TableInfo.Column("created_at", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCards.put("updated_at", new TableInfo.Column("updated_at", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysCards = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesCards = new HashSet<TableInfo.Index>(3);
        _indicesCards.add(new TableInfo.Index("index_cards_title", false, Arrays.asList("title"), Arrays.asList("ASC")));
        _indicesCards.add(new TableInfo.Index("index_cards_group", false, Arrays.asList("group"), Arrays.asList("ASC")));
        _indicesCards.add(new TableInfo.Index("index_cards_is_pinned", false, Arrays.asList("is_pinned"), Arrays.asList("ASC")));
        final TableInfo _infoCards = new TableInfo("cards", _columnsCards, _foreignKeysCards, _indicesCards);
        final TableInfo _existingCards = TableInfo.read(db, "cards");
        if (!_infoCards.equals(_existingCards)) {
          return new RoomOpenHelper.ValidationResult(false, "cards(com.quickvault.data.local.database.entity.CardEntity).\n"
                  + " Expected:\n" + _infoCards + "\n"
                  + " Found:\n" + _existingCards);
        }
        final HashMap<String, TableInfo.Column> _columnsCardFields = new HashMap<String, TableInfo.Column>(6);
        _columnsCardFields.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCardFields.put("card_id", new TableInfo.Column("card_id", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCardFields.put("label", new TableInfo.Column("label", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCardFields.put("encrypted_value", new TableInfo.Column("encrypted_value", "BLOB", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCardFields.put("is_required", new TableInfo.Column("is_required", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsCardFields.put("display_order", new TableInfo.Column("display_order", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysCardFields = new HashSet<TableInfo.ForeignKey>(1);
        _foreignKeysCardFields.add(new TableInfo.ForeignKey("cards", "CASCADE", "NO ACTION", Arrays.asList("card_id"), Arrays.asList("id")));
        final HashSet<TableInfo.Index> _indicesCardFields = new HashSet<TableInfo.Index>(1);
        _indicesCardFields.add(new TableInfo.Index("index_card_fields_card_id", false, Arrays.asList("card_id"), Arrays.asList("ASC")));
        final TableInfo _infoCardFields = new TableInfo("card_fields", _columnsCardFields, _foreignKeysCardFields, _indicesCardFields);
        final TableInfo _existingCardFields = TableInfo.read(db, "card_fields");
        if (!_infoCardFields.equals(_existingCardFields)) {
          return new RoomOpenHelper.ValidationResult(false, "card_fields(com.quickvault.data.local.database.entity.CardFieldEntity).\n"
                  + " Expected:\n" + _infoCardFields + "\n"
                  + " Found:\n" + _existingCardFields);
        }
        final HashMap<String, TableInfo.Column> _columnsAttachments = new HashMap<String, TableInfo.Column>(8);
        _columnsAttachments.put("id", new TableInfo.Column("id", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("card_id", new TableInfo.Column("card_id", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("file_name", new TableInfo.Column("file_name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("file_type", new TableInfo.Column("file_type", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("file_size", new TableInfo.Column("file_size", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("encrypted_data", new TableInfo.Column("encrypted_data", "BLOB", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("thumbnail_data", new TableInfo.Column("thumbnail_data", "BLOB", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsAttachments.put("created_at", new TableInfo.Column("created_at", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysAttachments = new HashSet<TableInfo.ForeignKey>(1);
        _foreignKeysAttachments.add(new TableInfo.ForeignKey("cards", "CASCADE", "NO ACTION", Arrays.asList("card_id"), Arrays.asList("id")));
        final HashSet<TableInfo.Index> _indicesAttachments = new HashSet<TableInfo.Index>(1);
        _indicesAttachments.add(new TableInfo.Index("index_attachments_card_id", false, Arrays.asList("card_id"), Arrays.asList("ASC")));
        final TableInfo _infoAttachments = new TableInfo("attachments", _columnsAttachments, _foreignKeysAttachments, _indicesAttachments);
        final TableInfo _existingAttachments = TableInfo.read(db, "attachments");
        if (!_infoAttachments.equals(_existingAttachments)) {
          return new RoomOpenHelper.ValidationResult(false, "attachments(com.quickvault.data.local.database.entity.AttachmentEntity).\n"
                  + " Expected:\n" + _infoAttachments + "\n"
                  + " Found:\n" + _existingAttachments);
        }
        return new RoomOpenHelper.ValidationResult(true, null);
      }
    }, "b06c2b631c168c9d8344da95f17a5cd0", "9ae8f88296682af742bced67cdeec5fb");
    final SupportSQLiteOpenHelper.Configuration _sqliteConfig = SupportSQLiteOpenHelper.Configuration.builder(config.context).name(config.name).callback(_openCallback).build();
    final SupportSQLiteOpenHelper _helper = config.sqliteOpenHelperFactory.create(_sqliteConfig);
    return _helper;
  }

  @Override
  @NonNull
  protected InvalidationTracker createInvalidationTracker() {
    final HashMap<String, String> _shadowTablesMap = new HashMap<String, String>(0);
    final HashMap<String, Set<String>> _viewTables = new HashMap<String, Set<String>>(0);
    return new InvalidationTracker(this, _shadowTablesMap, _viewTables, "cards","card_fields","attachments");
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
      _db.execSQL("DELETE FROM `cards`");
      _db.execSQL("DELETE FROM `card_fields`");
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
    _typeConvertersMap.put(CardDao.class, CardDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(CardFieldDao.class, CardFieldDao_Impl.getRequiredConverters());
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
  public CardDao cardDao() {
    if (_cardDao != null) {
      return _cardDao;
    } else {
      synchronized(this) {
        if(_cardDao == null) {
          _cardDao = new CardDao_Impl(this);
        }
        return _cardDao;
      }
    }
  }

  @Override
  public CardFieldDao cardFieldDao() {
    if (_cardFieldDao != null) {
      return _cardFieldDao;
    } else {
      synchronized(this) {
        if(_cardFieldDao == null) {
          _cardFieldDao = new CardFieldDao_Impl(this);
        }
        return _cardFieldDao;
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
