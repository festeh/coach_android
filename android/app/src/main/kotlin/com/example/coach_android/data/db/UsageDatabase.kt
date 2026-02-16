package com.example.coach_android.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [EventEntity::class, RuleCounterEntity::class, HookResultEntity::class],
    version = 2,
    exportSchema = false,
)
abstract class UsageDatabase : RoomDatabase() {
    abstract fun eventDao(): EventDao

    abstract fun ruleCounterDao(): RuleCounterDao

    abstract fun hookResultDao(): HookResultDao

    companion object {
        fun create(context: Context): UsageDatabase =
            Room
                .databaseBuilder(
                    context.applicationContext,
                    UsageDatabase::class.java,
                    "coach_usage.db",
                ).fallbackToDestructiveMigration(dropAllTables = true)
                .build()
    }
}
