package com.quickvault.data.local.database.dao;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityDeletionOrUpdateAdapter;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import com.quickvault.data.local.database.entity.CardFieldEntity;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Object;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import javax.annotation.processing.Generated;
import kotlin.Unit;
import kotlin.coroutines.Continuation;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class CardFieldDao_Impl implements CardFieldDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<CardFieldEntity> __insertionAdapterOfCardFieldEntity;

  private final EntityDeletionOrUpdateAdapter<CardFieldEntity> __deletionAdapterOfCardFieldEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteFieldsByCardId;

  public CardFieldDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfCardFieldEntity = new EntityInsertionAdapter<CardFieldEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `card_fields` (`id`,`card_id`,`label`,`encrypted_value`,`is_required`,`display_order`) VALUES (?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final CardFieldEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getCardId());
        statement.bindString(3, entity.getLabel());
        statement.bindBlob(4, entity.getEncryptedValue());
        final int _tmp = entity.isRequired() ? 1 : 0;
        statement.bindLong(5, _tmp);
        statement.bindLong(6, entity.getDisplayOrder());
      }
    };
    this.__deletionAdapterOfCardFieldEntity = new EntityDeletionOrUpdateAdapter<CardFieldEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "DELETE FROM `card_fields` WHERE `id` = ?";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final CardFieldEntity entity) {
        statement.bindString(1, entity.getId());
      }
    };
    this.__preparedStmtOfDeleteFieldsByCardId = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM card_fields WHERE card_id = ?";
        return _query;
      }
    };
  }

  @Override
  public Object insertField(final CardFieldEntity field,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfCardFieldEntity.insert(field);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object insertFields(final List<CardFieldEntity> fields,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __insertionAdapterOfCardFieldEntity.insert(fields);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteField(final CardFieldEntity field,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        __db.beginTransaction();
        try {
          __deletionAdapterOfCardFieldEntity.handle(field);
          __db.setTransactionSuccessful();
          return Unit.INSTANCE;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteFieldsByCardId(final String cardId,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteFieldsByCardId.acquire();
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
          __preparedStmtOfDeleteFieldsByCardId.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object getFieldsByCardId(final String cardId,
      final Continuation<? super List<CardFieldEntity>> $completion) {
    final String _sql = "SELECT * FROM card_fields WHERE card_id = ? ORDER BY display_order ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, cardId);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<List<CardFieldEntity>>() {
      @Override
      @NonNull
      public List<CardFieldEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfCardId = CursorUtil.getColumnIndexOrThrow(_cursor, "card_id");
          final int _cursorIndexOfLabel = CursorUtil.getColumnIndexOrThrow(_cursor, "label");
          final int _cursorIndexOfEncryptedValue = CursorUtil.getColumnIndexOrThrow(_cursor, "encrypted_value");
          final int _cursorIndexOfIsRequired = CursorUtil.getColumnIndexOrThrow(_cursor, "is_required");
          final int _cursorIndexOfDisplayOrder = CursorUtil.getColumnIndexOrThrow(_cursor, "display_order");
          final List<CardFieldEntity> _result = new ArrayList<CardFieldEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final CardFieldEntity _item;
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
            _item = new CardFieldEntity(_tmpId,_tmpCardId,_tmpLabel,_tmpEncryptedValue,_tmpIsRequired,_tmpDisplayOrder);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @NonNull
  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
