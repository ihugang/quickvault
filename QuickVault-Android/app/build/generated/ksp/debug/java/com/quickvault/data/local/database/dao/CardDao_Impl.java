package com.quickvault.data.local.database.dao;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.collection.ArrayMap;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityDeletionOrUpdateAdapter;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.room.util.RelationUtil;
import androidx.room.util.StringUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import com.quickvault.data.local.database.entity.AttachmentEntity;
import com.quickvault.data.local.database.entity.CardEntity;
import com.quickvault.data.local.database.entity.CardFieldEntity;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Long;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.StringBuilder;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Callable;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class CardDao_Impl implements CardDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<CardEntity> __insertionAdapterOfCardEntity;

  private final EntityDeletionOrUpdateAdapter<CardEntity> __updateAdapterOfCardEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteCard;

  private final SharedSQLiteStatement __preparedStmtOfUpdatePinStatus;

  public CardDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfCardEntity = new EntityInsertionAdapter<CardEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `cards` (`id`,`title`,`card_type`,`group`,`is_pinned`,`tags_json`,`created_at`,`updated_at`) VALUES (?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final CardEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        statement.bindString(3, entity.getCardType());
        statement.bindString(4, entity.getGroup());
        final int _tmp = entity.isPinned() ? 1 : 0;
        statement.bindLong(5, _tmp);
        statement.bindString(6, entity.getTagsJson());
        statement.bindLong(7, entity.getCreatedAt());
        statement.bindLong(8, entity.getUpdatedAt());
      }
    };
    this.__updateAdapterOfCardEntity = new EntityDeletionOrUpdateAdapter<CardEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "UPDATE OR ABORT `cards` SET `id` = ?,`title` = ?,`card_type` = ?,`group` = ?,`is_pinned` = ?,`tags_json` = ?,`created_at` = ?,`updated_at` = ? WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final CardEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getTitle());
        statement.bindString(3, entity.getCardType());
        statement.bindString(4, entity.getGroup());
        final int _tmp = entity.isPinned() ? 1 : 0;
        statement.bindLong(5, _tmp);
        statement.bindString(6, entity.getTagsJson());
        statement.bindLong(7, entity.getCreatedAt());
        statement.bindLong(8, entity.getUpdatedAt());
        statement.bindString(9, entity.getId());
      }
    };
    this.__preparedStmtOfDeleteCard = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM cards WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfUpdatePinStatus = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "UPDATE cards SET is_pinned = ?, updated_at = ? WHERE id = ?";
        return _query;
      }
    };
  }

  @Override
  public Object insertCard(final CardEntity card, final Continuation<? super Long> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Long>() {
      @Override
      @NonNull
      public Long call() throws Exception {
        __db.beginTransaction();
        try {
          final Long _result = __insertionAdapterOfCardEntity.insertAndReturnId(card);
          __db.setTransactionSuccessful();
          return _result;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object updateCard(final CardEntity card, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __updateAdapterOfCardEntity.handle(card);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteCard(final String cardId, final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteCard.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, cardId);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfDeleteCard.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object updatePinStatus(final String cardId, final boolean isPinned, final long updatedAt,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfUpdatePinStatus.acquire();
        int _argIndex = 1;
        final int _tmp = isPinned ? 1 : 0;
        _stmt.bindLong(_argIndex, _tmp);
        _argIndex = 2;
        _stmt.bindLong(_argIndex, updatedAt);
        _argIndex = 3;
        _stmt.bindString(_argIndex, cardId);
        try {
          __db.beginTransaction();
          try {
            _stmt.executeUpdateDelete();
            __db.setTransactionSuccessful();
            return Unit.INSTANCE;
          } finally {
            __db.endTransaction();
          }
        } finally {
          __preparedStmtOfUpdatePinStatus.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<CardWithFields>> getAllCardsWithFields() {
    final String _sql = "SELECT * FROM cards ORDER BY is_pinned DESC, updated_at DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return CoroutinesRoom.createFlow(__db, true, new String[] {"card_fields", "attachments",
        "cards"}, new Callable<List<CardWithFields>>() {
      @Override
      @NonNull
      public List<CardWithFields> call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfCardType = CursorUtil.getColumnIndexOrThrow(_cursor, "card_type");
            final int _cursorIndexOfGroup = CursorUtil.getColumnIndexOrThrow(_cursor, "group");
            final int _cursorIndexOfIsPinned = CursorUtil.getColumnIndexOrThrow(_cursor, "is_pinned");
            final int _cursorIndexOfTagsJson = CursorUtil.getColumnIndexOrThrow(_cursor, "tags_json");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "created_at");
            final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updated_at");
            final ArrayMap<String, ArrayList<CardFieldEntity>> _collectionFields = new ArrayMap<String, ArrayList<CardFieldEntity>>();
            final ArrayMap<String, ArrayList<AttachmentEntity>> _collectionAttachments = new ArrayMap<String, ArrayList<AttachmentEntity>>();
            while (_cursor.moveToNext()) {
              final String _tmpKey;
              _tmpKey = _cursor.getString(_cursorIndexOfId);
              if (!_collectionFields.containsKey(_tmpKey)) {
                _collectionFields.put(_tmpKey, new ArrayList<CardFieldEntity>());
              }
              final String _tmpKey_1;
              _tmpKey_1 = _cursor.getString(_cursorIndexOfId);
              if (!_collectionAttachments.containsKey(_tmpKey_1)) {
                _collectionAttachments.put(_tmpKey_1, new ArrayList<AttachmentEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipcardFieldsAscomQuickvaultDataLocalDatabaseEntityCardFieldEntity(_collectionFields);
            __fetchRelationshipattachmentsAscomQuickvaultDataLocalDatabaseEntityAttachmentEntity(_collectionAttachments);
            final List<CardWithFields> _result = new ArrayList<CardWithFields>(_cursor.getCount());
            while (_cursor.moveToNext()) {
              final CardWithFields _item;
              final CardEntity _tmpCard;
              final String _tmpId;
              _tmpId = _cursor.getString(_cursorIndexOfId);
              final String _tmpTitle;
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
              final String _tmpCardType;
              _tmpCardType = _cursor.getString(_cursorIndexOfCardType);
              final String _tmpGroup;
              _tmpGroup = _cursor.getString(_cursorIndexOfGroup);
              final boolean _tmpIsPinned;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfIsPinned);
              _tmpIsPinned = _tmp != 0;
              final String _tmpTagsJson;
              _tmpTagsJson = _cursor.getString(_cursorIndexOfTagsJson);
              final long _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
              final long _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getLong(_cursorIndexOfUpdatedAt);
              _tmpCard = new CardEntity(_tmpId,_tmpTitle,_tmpCardType,_tmpGroup,_tmpIsPinned,_tmpTagsJson,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<CardFieldEntity> _tmpFieldsCollection;
              final String _tmpKey_2;
              _tmpKey_2 = _cursor.getString(_cursorIndexOfId);
              _tmpFieldsCollection = _collectionFields.get(_tmpKey_2);
              final ArrayList<AttachmentEntity> _tmpAttachmentsCollection;
              final String _tmpKey_3;
              _tmpKey_3 = _cursor.getString(_cursorIndexOfId);
              _tmpAttachmentsCollection = _collectionAttachments.get(_tmpKey_3);
              _item = new CardWithFields(_tmpCard,_tmpFieldsCollection,_tmpAttachmentsCollection);
              _result.add(_item);
            }
            __db.setTransactionSuccessful();
            return _result;
          } finally {
            _cursor.close();
          }
        } finally {
          __db.endTransaction();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Object getCardWithFields(final String cardId,
      final Continuation<? super CardWithFields> $completion) {
    final String _sql = "SELECT * FROM cards WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, cardId);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, true, _cancellationSignal, new Callable<CardWithFields>() {
      @Override
      @Nullable
      public CardWithFields call() throws Exception {
        __db.beginTransaction();
        try {
          final Cursor _cursor = DBUtil.query(__db, _statement, true, null);
          try {
            final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
            final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
            final int _cursorIndexOfCardType = CursorUtil.getColumnIndexOrThrow(_cursor, "card_type");
            final int _cursorIndexOfGroup = CursorUtil.getColumnIndexOrThrow(_cursor, "group");
            final int _cursorIndexOfIsPinned = CursorUtil.getColumnIndexOrThrow(_cursor, "is_pinned");
            final int _cursorIndexOfTagsJson = CursorUtil.getColumnIndexOrThrow(_cursor, "tags_json");
            final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "created_at");
            final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updated_at");
            final ArrayMap<String, ArrayList<CardFieldEntity>> _collectionFields = new ArrayMap<String, ArrayList<CardFieldEntity>>();
            final ArrayMap<String, ArrayList<AttachmentEntity>> _collectionAttachments = new ArrayMap<String, ArrayList<AttachmentEntity>>();
            while (_cursor.moveToNext()) {
              final String _tmpKey;
              _tmpKey = _cursor.getString(_cursorIndexOfId);
              if (!_collectionFields.containsKey(_tmpKey)) {
                _collectionFields.put(_tmpKey, new ArrayList<CardFieldEntity>());
              }
              final String _tmpKey_1;
              _tmpKey_1 = _cursor.getString(_cursorIndexOfId);
              if (!_collectionAttachments.containsKey(_tmpKey_1)) {
                _collectionAttachments.put(_tmpKey_1, new ArrayList<AttachmentEntity>());
              }
            }
            _cursor.moveToPosition(-1);
            __fetchRelationshipcardFieldsAscomQuickvaultDataLocalDatabaseEntityCardFieldEntity(_collectionFields);
            __fetchRelationshipattachmentsAscomQuickvaultDataLocalDatabaseEntityAttachmentEntity(_collectionAttachments);
            final CardWithFields _result;
            if (_cursor.moveToFirst()) {
              final CardEntity _tmpCard;
              final String _tmpId;
              _tmpId = _cursor.getString(_cursorIndexOfId);
              final String _tmpTitle;
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
              final String _tmpCardType;
              _tmpCardType = _cursor.getString(_cursorIndexOfCardType);
              final String _tmpGroup;
              _tmpGroup = _cursor.getString(_cursorIndexOfGroup);
              final boolean _tmpIsPinned;
              final int _tmp;
              _tmp = _cursor.getInt(_cursorIndexOfIsPinned);
              _tmpIsPinned = _tmp != 0;
              final String _tmpTagsJson;
              _tmpTagsJson = _cursor.getString(_cursorIndexOfTagsJson);
              final long _tmpCreatedAt;
              _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
              final long _tmpUpdatedAt;
              _tmpUpdatedAt = _cursor.getLong(_cursorIndexOfUpdatedAt);
              _tmpCard = new CardEntity(_tmpId,_tmpTitle,_tmpCardType,_tmpGroup,_tmpIsPinned,_tmpTagsJson,_tmpCreatedAt,_tmpUpdatedAt);
              final ArrayList<CardFieldEntity> _tmpFieldsCollection;
              final String _tmpKey_2;
              _tmpKey_2 = _cursor.getString(_cursorIndexOfId);
              _tmpFieldsCollection = _collectionFields.get(_tmpKey_2);
              final ArrayList<AttachmentEntity> _tmpAttachmentsCollection;
              final String _tmpKey_3;
              _tmpKey_3 = _cursor.getString(_cursorIndexOfId);
              _tmpAttachmentsCollection = _collectionAttachments.get(_tmpKey_3);
              _result = new CardWithFields(_tmpCard,_tmpFieldsCollection,_tmpAttachmentsCollection);
            } else {
              _result = null;
            }
            __db.setTransactionSuccessful();
            return _result;
          } finally {
            _cursor.close();
            _statement.release();
          }
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<CardEntity>> searchCards(final String query) {
    final String _sql = "SELECT * FROM cards WHERE title LIKE '%' || ? || '%' ORDER BY is_pinned DESC, updated_at DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, query);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"cards"}, new Callable<List<CardEntity>>() {
      @Override
      @NonNull
      public List<CardEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfCardType = CursorUtil.getColumnIndexOrThrow(_cursor, "card_type");
          final int _cursorIndexOfGroup = CursorUtil.getColumnIndexOrThrow(_cursor, "group");
          final int _cursorIndexOfIsPinned = CursorUtil.getColumnIndexOrThrow(_cursor, "is_pinned");
          final int _cursorIndexOfTagsJson = CursorUtil.getColumnIndexOrThrow(_cursor, "tags_json");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "created_at");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updated_at");
          final List<CardEntity> _result = new ArrayList<CardEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final CardEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpCardType;
            _tmpCardType = _cursor.getString(_cursorIndexOfCardType);
            final String _tmpGroup;
            _tmpGroup = _cursor.getString(_cursorIndexOfGroup);
            final boolean _tmpIsPinned;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfIsPinned);
            _tmpIsPinned = _tmp != 0;
            final String _tmpTagsJson;
            _tmpTagsJson = _cursor.getString(_cursorIndexOfTagsJson);
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            final long _tmpUpdatedAt;
            _tmpUpdatedAt = _cursor.getLong(_cursorIndexOfUpdatedAt);
            _item = new CardEntity(_tmpId,_tmpTitle,_tmpCardType,_tmpGroup,_tmpIsPinned,_tmpTagsJson,_tmpCreatedAt,_tmpUpdatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public Flow<List<CardEntity>> getCardsByGroup(final String group) {
    final String _sql = "SELECT * FROM cards WHERE `group` = ? ORDER BY is_pinned DESC, updated_at DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, group);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"cards"}, new Callable<List<CardEntity>>() {
      @Override
      @NonNull
      public List<CardEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfCardType = CursorUtil.getColumnIndexOrThrow(_cursor, "card_type");
          final int _cursorIndexOfGroup = CursorUtil.getColumnIndexOrThrow(_cursor, "group");
          final int _cursorIndexOfIsPinned = CursorUtil.getColumnIndexOrThrow(_cursor, "is_pinned");
          final int _cursorIndexOfTagsJson = CursorUtil.getColumnIndexOrThrow(_cursor, "tags_json");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "created_at");
          final int _cursorIndexOfUpdatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "updated_at");
          final List<CardEntity> _result = new ArrayList<CardEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final CardEntity _item;
            final String _tmpId;
            _tmpId = _cursor.getString(_cursorIndexOfId);
            final String _tmpTitle;
            _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            final String _tmpCardType;
            _tmpCardType = _cursor.getString(_cursorIndexOfCardType);
            final String _tmpGroup;
            _tmpGroup = _cursor.getString(_cursorIndexOfGroup);
            final boolean _tmpIsPinned;
            final int _tmp;
            _tmp = _cursor.getInt(_cursorIndexOfIsPinned);
            _tmpIsPinned = _tmp != 0;
            final String _tmpTagsJson;
            _tmpTagsJson = _cursor.getString(_cursorIndexOfTagsJson);
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            final long _tmpUpdatedAt;
            _tmpUpdatedAt = _cursor.getLong(_cursorIndexOfUpdatedAt);
            _item = new CardEntity(_tmpId,_tmpTitle,_tmpCardType,_tmpGroup,_tmpIsPinned,_tmpTagsJson,_tmpCreatedAt,_tmpUpdatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }

  private void __fetchRelationshipcardFieldsAscomQuickvaultDataLocalDatabaseEntityCardFieldEntity(
      @NonNull final ArrayMap<String, ArrayList<CardFieldEntity>> _map) {
    final Set<String> __mapKeySet = _map.keySet();
    if (__mapKeySet.isEmpty()) {
      return;
    }
    if (_map.size() > RoomDatabase.MAX_BIND_PARAMETER_CNT) {
      RelationUtil.recursiveFetchArrayMap(_map, true, (map) -> {
        __fetchRelationshipcardFieldsAscomQuickvaultDataLocalDatabaseEntityCardFieldEntity(map);
        return Unit.INSTANCE;
      });
      return;
    }
    final StringBuilder _stringBuilder = StringUtil.newStringBuilder();
    _stringBuilder.append("SELECT `id`,`card_id`,`label`,`encrypted_value`,`is_required`,`display_order` FROM `card_fields` WHERE `card_id` IN (");
    final int _inputSize = __mapKeySet.size();
    StringUtil.appendPlaceholders(_stringBuilder, _inputSize);
    _stringBuilder.append(")");
    final String _sql = _stringBuilder.toString();
    final int _argCount = 0 + _inputSize;
    final RoomSQLiteQuery _stmt = RoomSQLiteQuery.acquire(_sql, _argCount);
    int _argIndex = 1;
    for (String _item : __mapKeySet) {
      _stmt.bindString(_argIndex, _item);
      _argIndex++;
    }
    final Cursor _cursor = DBUtil.query(__db, _stmt, false, null);
    try {
      final int _itemKeyIndex = CursorUtil.getColumnIndex(_cursor, "card_id");
      if (_itemKeyIndex == -1) {
        return;
      }
      final int _cursorIndexOfId = 0;
      final int _cursorIndexOfCardId = 1;
      final int _cursorIndexOfLabel = 2;
      final int _cursorIndexOfEncryptedValue = 3;
      final int _cursorIndexOfIsRequired = 4;
      final int _cursorIndexOfDisplayOrder = 5;
      while (_cursor.moveToNext()) {
        final String _tmpKey;
        _tmpKey = _cursor.getString(_itemKeyIndex);
        final ArrayList<CardFieldEntity> _tmpRelation = _map.get(_tmpKey);
        if (_tmpRelation != null) {
          final CardFieldEntity _item_1;
          final String _tmpId;
          _tmpId = _cursor.getString(_cursorIndexOfId);
          final String _tmpCardId;
          _tmpCardId = _cursor.getString(_cursorIndexOfCardId);
          final String _tmpLabel;
          _tmpLabel = _cursor.getString(_cursorIndexOfLabel);
          final byte[] _tmpEncryptedValue;
          _tmpEncryptedValue = _cursor.getBlob(_cursorIndexOfEncryptedValue);
          final boolean _tmpIsRequired;
          final int _tmp;
          _tmp = _cursor.getInt(_cursorIndexOfIsRequired);
          _tmpIsRequired = _tmp != 0;
          final int _tmpDisplayOrder;
          _tmpDisplayOrder = _cursor.getInt(_cursorIndexOfDisplayOrder);
          _item_1 = new CardFieldEntity(_tmpId,_tmpCardId,_tmpLabel,_tmpEncryptedValue,_tmpIsRequired,_tmpDisplayOrder);
          _tmpRelation.add(_item_1);
        }
      }
    } finally {
      _cursor.close();
    }
  }

  private void __fetchRelationshipattachmentsAscomQuickvaultDataLocalDatabaseEntityAttachmentEntity(
      @NonNull final ArrayMap<String, ArrayList<AttachmentEntity>> _map) {
    final Set<String> __mapKeySet = _map.keySet();
    if (__mapKeySet.isEmpty()) {
      return;
    }
    if (_map.size() > RoomDatabase.MAX_BIND_PARAMETER_CNT) {
      RelationUtil.recursiveFetchArrayMap(_map, true, (map) -> {
        __fetchRelationshipattachmentsAscomQuickvaultDataLocalDatabaseEntityAttachmentEntity(map);
        return Unit.INSTANCE;
      });
      return;
    }
    final StringBuilder _stringBuilder = StringUtil.newStringBuilder();
    _stringBuilder.append("SELECT `id`,`card_id`,`file_name`,`file_type`,`file_size`,`encrypted_data`,`thumbnail_data`,`created_at` FROM `attachments` WHERE `card_id` IN (");
    final int _inputSize = __mapKeySet.size();
    StringUtil.appendPlaceholders(_stringBuilder, _inputSize);
    _stringBuilder.append(")");
    final String _sql = _stringBuilder.toString();
    final int _argCount = 0 + _inputSize;
    final RoomSQLiteQuery _stmt = RoomSQLiteQuery.acquire(_sql, _argCount);
    int _argIndex = 1;
    for (String _item : __mapKeySet) {
      _stmt.bindString(_argIndex, _item);
      _argIndex++;
    }
    final Cursor _cursor = DBUtil.query(__db, _stmt, false, null);
    try {
      final int _itemKeyIndex = CursorUtil.getColumnIndex(_cursor, "card_id");
      if (_itemKeyIndex == -1) {
        return;
      }
      final int _cursorIndexOfId = 0;
      final int _cursorIndexOfCardId = 1;
      final int _cursorIndexOfFileName = 2;
      final int _cursorIndexOfFileType = 3;
      final int _cursorIndexOfFileSize = 4;
      final int _cursorIndexOfEncryptedData = 5;
      final int _cursorIndexOfThumbnailData = 6;
      final int _cursorIndexOfCreatedAt = 7;
      while (_cursor.moveToNext()) {
        final String _tmpKey;
        _tmpKey = _cursor.getString(_itemKeyIndex);
        final ArrayList<AttachmentEntity> _tmpRelation = _map.get(_tmpKey);
        if (_tmpRelation != null) {
          final AttachmentEntity _item_1;
          final String _tmpId;
          _tmpId = _cursor.getString(_cursorIndexOfId);
          final String _tmpCardId;
          _tmpCardId = _cursor.getString(_cursorIndexOfCardId);
          final String _tmpFileName;
          _tmpFileName = _cursor.getString(_cursorIndexOfFileName);
          final String _tmpFileType;
          _tmpFileType = _cursor.getString(_cursorIndexOfFileType);
          final long _tmpFileSize;
          _tmpFileSize = _cursor.getLong(_cursorIndexOfFileSize);
          final byte[] _tmpEncryptedData;
          _tmpEncryptedData = _cursor.getBlob(_cursorIndexOfEncryptedData);
          final byte[] _tmpThumbnailData;
          if (_cursor.isNull(_cursorIndexOfThumbnailData)) {
            _tmpThumbnailData = null;
          } else {
            _tmpThumbnailData = _cursor.getBlob(_cursorIndexOfThumbnailData);
          }
          final long _tmpCreatedAt;
          _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
          _item_1 = new AttachmentEntity(_tmpId,_tmpCardId,_tmpFileName,_tmpFileType,_tmpFileSize,_tmpEncryptedData,_tmpThumbnailData,_tmpCreatedAt);
          _tmpRelation.add(_item_1);
        }
      }
    } finally {
      _cursor.close();
    }
  }
}
