package com.quickvault.data.local.database.dao;

import android.database.Cursor;
import android.os.CancellationSignal;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.room.CoroutinesRoom;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import com.quickvault.data.local.database.entity.AttachmentEntity;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Integer;
import java.lang.Long;
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
import kotlinx.coroutines.flow.Flow;

@Generated("androidx.room.RoomProcessor")
@SuppressWarnings({"unchecked", "deprecation"})
public final class AttachmentDao_Impl implements AttachmentDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<AttachmentEntity> __insertionAdapterOfAttachmentEntity;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAttachment;

  private final SharedSQLiteStatement __preparedStmtOfDeleteAttachmentsByCardId;

  public AttachmentDao_Impl(@NonNull final RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfAttachmentEntity = new EntityInsertionAdapter<AttachmentEntity>(__db) {
      @Override
      @NonNull
      protected String createQuery() {
        return "INSERT OR REPLACE INTO `attachments` (`id`,`card_id`,`file_name`,`file_type`,`file_size`,`encrypted_data`,`thumbnail_data`,`created_at`) VALUES (?,?,?,?,?,?,?,?)";
      }

      @Override
      protected void bind(@NonNull final SupportSQLiteStatement statement,
          @NonNull final AttachmentEntity entity) {
        statement.bindString(1, entity.getId());
        statement.bindString(2, entity.getCardId());
        statement.bindString(3, entity.getFileName());
        statement.bindString(4, entity.getFileType());
        statement.bindLong(5, entity.getFileSize());
        statement.bindBlob(6, entity.getEncryptedData());
        if (entity.getThumbnailData() == null) {
          statement.bindNull(7);
        } else {
          statement.bindBlob(7, entity.getThumbnailData());
        }
        statement.bindLong(8, entity.getCreatedAt());
      }
    };
    this.__preparedStmtOfDeleteAttachment = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM attachments WHERE id = ?";
        return _query;
      }
    };
    this.__preparedStmtOfDeleteAttachmentsByCardId = new SharedSQLiteStatement(__db) {
      @Override
      @NonNull
      public String createQuery() {
        final String _query = "DELETE FROM attachments WHERE card_id = ?";
        return _query;
      }
    };
  }

  @Override
  public Object insertAttachment(final AttachmentEntity attachment,
      final Continuation<? super Long> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Long>() {
      @Override
      @NonNull
      public Long call() throws Exception {
        __db.beginTransaction();
        try {
          final Long _result = __insertionAdapterOfAttachmentEntity.insertAndReturnId(attachment);
          __db.setTransactionSuccessful();
          return _result;
        } finally {
          __db.endTransaction();
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteAttachment(final String attachmentId,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAttachment.acquire();
        int _argIndex = 1;
        _stmt.bindString(_argIndex, attachmentId);
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
          __preparedStmtOfDeleteAttachment.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Object deleteAttachmentsByCardId(final String cardId,
      final Continuation<? super Unit> $completion) {
    return CoroutinesRoom.execute(__db, true, new Callable<Unit>() {
      @Override
      @NonNull
      public Unit call() throws Exception {
        final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteAttachmentsByCardId.acquire();
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
          __preparedStmtOfDeleteAttachmentsByCardId.release(_stmt);
        }
      }
    }, $completion);
  }

  @Override
  public Flow<List<AttachmentEntity>> getAttachmentsByCardId(final String cardId) {
    final String _sql = "SELECT * FROM attachments WHERE card_id = ? ORDER BY created_at DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, cardId);
    return CoroutinesRoom.createFlow(__db, false, new String[] {"attachments"}, new Callable<List<AttachmentEntity>>() {
      @Override
      @NonNull
      public List<AttachmentEntity> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfCardId = CursorUtil.getColumnIndexOrThrow(_cursor, "card_id");
          final int _cursorIndexOfFileName = CursorUtil.getColumnIndexOrThrow(_cursor, "file_name");
          final int _cursorIndexOfFileType = CursorUtil.getColumnIndexOrThrow(_cursor, "file_type");
          final int _cursorIndexOfFileSize = CursorUtil.getColumnIndexOrThrow(_cursor, "file_size");
          final int _cursorIndexOfEncryptedData = CursorUtil.getColumnIndexOrThrow(_cursor, "encrypted_data");
          final int _cursorIndexOfThumbnailData = CursorUtil.getColumnIndexOrThrow(_cursor, "thumbnail_data");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "created_at");
          final List<AttachmentEntity> _result = new ArrayList<AttachmentEntity>(_cursor.getCount());
          while (_cursor.moveToNext()) {
            final AttachmentEntity _item;
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
            _item = new AttachmentEntity(_tmpId,_tmpCardId,_tmpFileName,_tmpFileType,_tmpFileSize,_tmpEncryptedData,_tmpThumbnailData,_tmpCreatedAt);
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
  public Object getAttachmentById(final String attachmentId,
      final Continuation<? super AttachmentEntity> $completion) {
    final String _sql = "SELECT * FROM attachments WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, attachmentId);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<AttachmentEntity>() {
      @Override
      @Nullable
      public AttachmentEntity call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfCardId = CursorUtil.getColumnIndexOrThrow(_cursor, "card_id");
          final int _cursorIndexOfFileName = CursorUtil.getColumnIndexOrThrow(_cursor, "file_name");
          final int _cursorIndexOfFileType = CursorUtil.getColumnIndexOrThrow(_cursor, "file_type");
          final int _cursorIndexOfFileSize = CursorUtil.getColumnIndexOrThrow(_cursor, "file_size");
          final int _cursorIndexOfEncryptedData = CursorUtil.getColumnIndexOrThrow(_cursor, "encrypted_data");
          final int _cursorIndexOfThumbnailData = CursorUtil.getColumnIndexOrThrow(_cursor, "thumbnail_data");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "created_at");
          final AttachmentEntity _result;
          if (_cursor.moveToFirst()) {
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
            _result = new AttachmentEntity(_tmpId,_tmpCardId,_tmpFileName,_tmpFileType,_tmpFileSize,_tmpEncryptedData,_tmpThumbnailData,_tmpCreatedAt);
          } else {
            _result = null;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Object getAttachmentCount(final String cardId,
      final Continuation<? super Integer> $completion) {
    final String _sql = "SELECT COUNT(*) FROM attachments WHERE card_id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, cardId);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<Integer>() {
      @Override
      @NonNull
      public Integer call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final Integer _result;
          if (_cursor.moveToFirst()) {
            final int _tmp;
            _tmp = _cursor.getInt(0);
            _result = _tmp;
          } else {
            _result = 0;
          }
          return _result;
        } finally {
          _cursor.close();
          _statement.release();
        }
      }
    }, $completion);
  }

  @Override
  public Object getTotalAttachmentSize(final String cardId,
      final Continuation<? super Long> $completion) {
    final String _sql = "SELECT SUM(file_size) FROM attachments WHERE card_id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindString(_argIndex, cardId);
    final CancellationSignal _cancellationSignal = DBUtil.createCancellationSignal();
    return CoroutinesRoom.execute(__db, false, _cancellationSignal, new Callable<Long>() {
      @Override
      @Nullable
      public Long call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final Long _result;
          if (_cursor.moveToFirst()) {
            final Long _tmp;
            if (_cursor.isNull(0)) {
              _tmp = null;
            } else {
              _tmp = _cursor.getLong(0);
            }
            _result = _tmp;
          } else {
            _result = null;
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
