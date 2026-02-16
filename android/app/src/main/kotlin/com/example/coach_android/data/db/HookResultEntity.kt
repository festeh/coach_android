package com.example.coach_android.data.db

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Index
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Entity(
    tableName = "hook_results",
    indices = [Index("created_at")],
)
data class HookResultEntity(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "hook_id") val hookId: String,
    val content: String,
    @ColumnInfo(name = "created_at") val createdAt: Long,
)

@Dao
interface HookResultDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(result: HookResultEntity)

    @Query("SELECT * FROM hook_results ORDER BY created_at DESC LIMIT 1000")
    fun getAll(): Flow<List<HookResultEntity>>

    @Query("SELECT COUNT(*) FROM hook_results")
    suspend fun count(): Int

    @Query(
        """
        DELETE FROM hook_results WHERE id NOT IN (
            SELECT id FROM hook_results ORDER BY created_at DESC LIMIT :keepCount
        )
        """,
    )
    suspend fun cleanup(keepCount: Int = 1000)
}
