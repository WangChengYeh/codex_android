use std::sync::Mutex as StdMutex;

use tokio::sync::broadcast;
use tokio::sync::mpsc;
use tokio::task::JoinHandle;

pub(crate) struct ExecCommandSession {
    /// Queue for writing bytes to the process stdin (PTY master write side).
    writer_tx: mpsc::Sender<Vec<u8>>,
    /// Broadcast stream of output chunks read from the PTY. New subscribers
    /// receive only chunks emitted after they subscribe.
    output_tx: broadcast::Sender<Vec<u8>>,

    /// Child killer function for termination on drop
    killer: StdMutex<Option<Box<dyn Fn() + Send + Sync>>>,

    /// JoinHandle for the blocking PTY reader task.
    reader_handle: StdMutex<Option<JoinHandle<()>>>,

    /// JoinHandle for the stdin writer task.
    writer_handle: StdMutex<Option<JoinHandle<()>>>,

    /// JoinHandle for the child wait task.
    wait_handle: StdMutex<Option<JoinHandle<()>>>,
}

impl ExecCommandSession {
    pub(crate) fn new(
        writer_tx: mpsc::Sender<Vec<u8>>,
        output_tx: broadcast::Sender<Vec<u8>>,
        killer: Box<dyn Fn() + Send + Sync>,
        reader_handle: JoinHandle<()>,
        writer_handle: JoinHandle<()>,
        wait_handle: JoinHandle<()>,
    ) -> Self {
        Self {
            writer_tx,
            output_tx,
            killer: StdMutex::new(Some(killer)),
            reader_handle: StdMutex::new(Some(reader_handle)),
            writer_handle: StdMutex::new(Some(writer_handle)),
            wait_handle: StdMutex::new(Some(wait_handle)),
        }
    }

    pub(crate) fn writer_sender(&self) -> mpsc::Sender<Vec<u8>> {
        self.writer_tx.clone()
    }

    pub(crate) fn output_receiver(&self) -> broadcast::Receiver<Vec<u8>> {
        self.output_tx.subscribe()
    }
}

impl std::fmt::Debug for ExecCommandSession {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ExecCommandSession")
            .field("writer_tx", &self.writer_tx)
            .field("output_tx", &self.output_tx)
            .field("killer", &"<killer function>")
            .field("reader_handle", &"<reader handle>")
            .field("writer_handle", &"<writer handle>")
            .field("wait_handle", &"<wait handle>")
            .finish()
    }
}

impl Drop for ExecCommandSession {
    fn drop(&mut self) {
        // Best-effort: terminate child first so blocking tasks can complete.
        if let Ok(mut killer_opt) = self.killer.lock()
            && let Some(killer) = killer_opt.take()
        {
            killer();
        }

        // Abort background tasks; they may already have exited after kill.
        if let Ok(mut h) = self.reader_handle.lock()
            && let Some(handle) = h.take()
        {
            handle.abort();
        }
        if let Ok(mut h) = self.writer_handle.lock()
            && let Some(handle) = h.take()
        {
            handle.abort();
        }
        if let Ok(mut h) = self.wait_handle.lock()
            && let Some(handle) = h.take()
        {
            handle.abort();
        }
    }
}