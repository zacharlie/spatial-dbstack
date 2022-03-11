from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from pathlib import Path
import time
from os import environ as env
from os import system

# give database a chance to boot up
time.sleep(int(env["STARTUP_DELAY"]))

if __name__ == "__main__":
    # patterns = ["*"]  # watch all files
    patterns = [
        "*.shp",
        "*.json",
        "*.geojson",
        "*.gpkg",
        "*.csv",
    ]
    ignore_patterns = [
        # ignore pycache
        "__pycache__/",
        "*/__pycache__/",
        "*/*/__pycache__/",
        "*/*/*/__pycache__/",
        "*.py[cod]",
        "*/*.py[cod]",
        "*/*/*.py[cod]",
        "*/*/*/*.py[cod]",
    ]
    ignore_directories = False
    case_sensitive = True
    my_event_handler = PatternMatchingEventHandler(
        patterns, ignore_patterns, ignore_directories, case_sensitive
    )


application_root = Path(env["TARGET"])
application_path = application_root.as_posix()


def on_created(event):
    print(f"{event.src_path} has been created!")
    ingest_geodata()


def on_deleted(event):
    print(f"File / path deleted: {event.src_path}!")
    ingest_geodata()


def on_modified(event):
    print(f"{event.src_path} has been modified")
    ingest_geodata()


def on_moved(event):
    print(f"File moved {event.src_path} to {event.dest_path}")
    ingest_geodata()


def ingest_geodata():
    system("/ingest_geodata.sh")


ingest_geodata()

my_event_handler.on_created = on_created
my_event_handler.on_deleted = on_deleted
my_event_handler.on_modified = on_modified
my_event_handler.on_moved = on_moved
go_recursively = True
my_observer = Observer()
my_observer.schedule(my_event_handler, application_path, recursive=go_recursively)

print("Watcher ready")

my_observer.start()

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    my_observer.stop()
    my_observer.join()
