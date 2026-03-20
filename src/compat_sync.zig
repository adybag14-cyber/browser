const std = @import("std");

pub const Mutex = struct {
    inner: std.c.pthread_mutex_t = std.c.PTHREAD_MUTEX_INITIALIZER,

    pub fn lock(self: *Mutex) void {
        _ = std.c.pthread_mutex_lock(&self.inner);
    }

    pub fn unlock(self: *Mutex) void {
        _ = std.c.pthread_mutex_unlock(&self.inner);
    }

    pub fn tryLock(self: *Mutex) bool {
        return std.c.pthread_mutex_trylock(&self.inner) == .SUCCESS;
    }
};

pub const WaitGroup = struct {
    mutex: std.c.pthread_mutex_t = std.c.PTHREAD_MUTEX_INITIALIZER,
    cond: std.c.pthread_cond_t = std.c.PTHREAD_COND_INITIALIZER,
    count: usize = 0,

    pub fn start(self: *WaitGroup) void {
        self.startMany(1);
    }

    pub fn startMany(self: *WaitGroup, n: usize) void {
        _ = std.c.pthread_mutex_lock(&self.mutex);
        self.count += n;
        _ = std.c.pthread_mutex_unlock(&self.mutex);
    }

    pub fn finish(self: *WaitGroup) void {
        _ = std.c.pthread_mutex_lock(&self.mutex);
        if (self.count > 0) self.count -= 1;
        if (self.count == 0) {
            _ = std.c.pthread_cond_broadcast(&self.cond);
        }
        _ = std.c.pthread_mutex_unlock(&self.mutex);
    }

    pub fn wait(self: *WaitGroup) void {
        _ = std.c.pthread_mutex_lock(&self.mutex);
        defer _ = std.c.pthread_mutex_unlock(&self.mutex);
        while (self.count != 0) {
            _ = std.c.pthread_cond_wait(&self.cond, &self.mutex);
        }
    }
};
