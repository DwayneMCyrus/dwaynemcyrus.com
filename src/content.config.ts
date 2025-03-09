// Import the glob loader
import { glob } from "astro/loaders";
// Import utilities from `astro:content`
import { z, defineCollection } from "astro:content";
// Define a `loader` and `schema` for each collection
const blog = defineCollection({
  // Load Markdown and MDX files in the `src/content/blog/` directory.
    loader: glob({ pattern: '**/[^_]*.md', base: "./src/content/blog" }),
    // Type-check frontmatter using a schema
    schema: z.object({
      title: z.string(),
      date: z.date(),
      description: z.string(),
      author: z.string(),
      image: z.object({
        url: z.string(),
        alt: z.string()
      }),
      tags: z.array(z.string())
    })
});

const notes = defineCollection({
  // Load Markdown and MDX files in the 'src/content/notes' directory.
  loader: glob({ pattern: '**/[^_]*.md', base: "./src/content/notes" }),
  // Type-check frontmatter using a schema.
  schema: z.object({
    title: z.string(),
    description: z.string(),
    tags: z.array(z.string()),
  }),
});

// Export a single `collections` object to register your collection(s)
export const collections = { blog, notes };