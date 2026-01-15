# Content Upload Quick Reference

## File Structure Created/Modified

```
TLMS-project-main/
├── Shared/
│   ├── Models/
│   │   └── CourseModels.swift ✅ MODIFIED (Added content fields to Lesson)
│   └── Utils/
│       └── MediaPicker.swift ✨ NEW (Video, PDF, Keynote pickers)
│
└── Educator/
    ├── View/
    │   ├── CourseStructureView.swift ✅ MODIFIED (Added content navigation)
    │   ├── LessonDetailView.swift ✅ MODIFIED (Added content navigation)
    │   └── LessonContentEditorView.swift ✨ NEW (Main content editor)
    │
    └── ViewModel/
        └── CourseCreationViewModel.swift ✅ MODIFIED (Added content methods)
```

## Content Type Support Matrix

| Content Type   | Icon | Upload Method | Max Size | File Types | Description Required |
|---------------|------|---------------|----------|------------|---------------------|
| Text          | 📝   | Direct Input  | N/A      | N/A        | ❌ No               |
| Video         | ▶️   | File Picker   | 100MB    | MP4, MOV   | ✅ Yes              |
| PDF           | 📄   | File Picker   | 50MB     | .pdf       | ✅ Yes              |
| Presentation  | 📊   | File Picker   | 100MB    | .key, .ppt | ✅ Yes              |
| Quiz          | ✅   | Quiz Editor   | N/A      | N/A        | ❌ N/A              |

## Navigation Flow

```
CourseStructureView
    └─ Module Card (Expanded)
        └─ Lesson Row
            ├─ [Content Menu] ──→ Select Type ──→ LessonContentEditorView
            │                                          ├─ Text Editor
            │                                          ├─ Video Upload + Description
            │                                          ├─ PDF Upload + Description
            │                                          └─ Keynote Upload + Description
            │
            └─ [Edit Quiz] ────→ LessonQuizEditorView (Existing)

LessonDetailView
    └─ Content Type Selection
        └─ Select Type (non-Quiz) ──→ LessonContentEditorView
        └─ Select Quiz ──────────────→ (Stays in Lesson Detail)
```

## UI Indicators

- 🟢 Green checkmark = Content added
- ➕ Plus icon = No content yet
- ✏️ Pencil icon = Edit existing content
- 🎯 Quiz badge = Quiz lesson

## Key Features

✅ **Automatic Navigation**
- Selecting content type automatically opens appropriate editor
- Quiz type opens Quiz Editor
- Other types open Content Editor

✅ **Smart Button Labels**
- "Content" when no content exists
- "Edit" when content exists
- Always "Edit Quiz" for quiz lessons

✅ **Visual Feedback**
- Green checkmark shows content completion status
- File upload shows selected file with icon
- Dashed border for upload area
- Success alert after saving

✅ **iOS Native**
- Uses system document picker
- Supports iCloud Drive
- Proper file type filtering
- File size validation

## Common Operations

### Create New Lesson with Text Content
1. Click "Add Lesson" in module
2. Enter lesson name
3. Click "Content" button
4. Select "Text"
5. → Opens Content Editor
6. Write content
7. Save

### Upload Video Lesson
1. Select existing lesson or create new
2. Click "Content" button
3. Select "Video"
4. → Opens Content Editor
5. Tap upload area
6. → iOS picker opens
7. Select video file
8. Add description
9. Save

### Edit Existing Content
1. Lesson shows green ✓
2. Click "Edit" button
3. → Opens Content Editor with data
4. Modify content
5. Save

### Switch Content Type
1. Open lesson in Content Editor
2. Go back
3. Select different content type from menu
4. → Opens Content Editor for new type
5. Previous content is cleared
